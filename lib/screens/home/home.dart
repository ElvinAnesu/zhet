import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zhet/services/ad_service.dart';
import 'create_ad.dart';
import 'orders.dart';
import 'profile_screen.dart';
import 'package:zhet/services/chat_service.dart';
import 'package:zhet/screens/chat/chat_detail_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  final AdService _adService = AdService();
  final ChatService _chatService = ChatService();

  // Lists to store ads from the database
  List<Ad> _usdAds = [];
  List<Ad> _zwgAds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAds();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _loadAds();
    }
  }

  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load USD ads
      if (_tabController.index == 0) {
        _usdAds = await _adService.getActiveAdsByCurrency('USD');
      } else {
        // Load ZWG ads
        _zwgAds = await _adService.getActiveAdsByCurrency('ZWG');
      }
    } catch (e) {
      print('Error loading ads: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Ad> _filterAds(List<Ad> ads, String query) {
    if (query.isEmpty) return ads;
    return ads.where((ad) {
      final String searchableText =
          '${ad.userProfile?.fullName ?? ''} ${ad.location} ${ad.amount} ${ad.getFormattedRate()}'
              .toLowerCase();
      return searchableText.contains(query.toLowerCase());
    }).toList();
  }

  Widget _buildAdCard(Ad ad, bool isUsd) {
    final bool isCurrentUserAd = ad.isCurrentUser;
    final String? fullName = ad.userProfile?.fullName;
    final double? rating = ad.userProfile?.rating;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName ?? 'Unknown User',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Text(
                  ad.getRelativeTime(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${ad.amount.toStringAsFixed(0)} ${isUsd ? 'USD' : 'ZWG'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rate: ${ad.getFormattedRate()}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Location: ${ad.location}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            if (ad.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Description: ${ad.description}',
                style: GoogleFonts.poppins(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            if (!isCurrentUserAd) // Only show the chat button if it's not the current user's ad
              ElevatedButton(
                onPressed: () async {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    // Get or create a chat room with the ad owner
                    final chatRoom = await _chatService.getOrCreateChatRoom(
                      ad.userId,
                    );

                    // Close loading dialog
                    Navigator.pop(context);

                    if (chatRoom != null) {
                      // Navigate to chat detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            chatRoom: chatRoom,
                          ),
                        ),
                      );
                    } else {
                      // Show error
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Failed to start chat. Please try again.'),
                        ),
                      );
                    }
                  } catch (e) {
                    // Close loading dialog
                    Navigator.pop(context);

                    // Show error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                      ),
                    );
                    debugPrint('Error starting chat: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  'Chat',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Your Ad',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search ads...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
                'Zhet',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAds,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                'USD',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Tab(
              child: Text(
                'ZWG',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // USD Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filterAds(_usdAds, _searchQuery).isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No USD ads found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadAds,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAds,
                      child: ListView.builder(
                        itemCount: _filterAds(_usdAds, _searchQuery).length,
                        itemBuilder: (context, index) {
                          return _buildAdCard(
                            _filterAds(_usdAds, _searchQuery)[index],
                            true,
                          );
                        },
                      ),
                    ),

          // ZWG Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filterAds(_zwgAds, _searchQuery).isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ZWG ads found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadAds,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAds,
                      child: ListView.builder(
                        itemCount: _filterAds(_zwgAds, _searchQuery).length,
                        itemBuilder: (context, index) {
                          return _buildAdCard(
                            _filterAds(_zwgAds, _searchQuery)[index],
                            false,
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildExchangeScreen(),
          const Orders(),
          const CreateAd(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;

            // If going to the exchange tab, refresh the ads
            if (index == 0) {
              _loadAds();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Exchange',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Ads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
