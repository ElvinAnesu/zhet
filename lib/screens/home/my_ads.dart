import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zhet/services/ad_service.dart';

class MyAds extends StatefulWidget {
  const MyAds({super.key});

  @override
  State<MyAds> createState() => _MyAdsState();
}

class _MyAdsState extends State<MyAds> {
  final AdService _adService = AdService();
  List<Ad> _activeAds = [];
  List<Ad> _inactiveAds = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allAds = await _adService.getCurrentUserAds(includeInactive: true);

      // Split into active and inactive ads
      _activeAds = allAds.where((ad) => ad.isActive).toList();
      _inactiveAds = allAds.where((ad) => !ad.isActive).toList();
    } catch (e) {
      print('Error loading user ads: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reactivateAd(Ad ad) async {
    try {
      final success = await _adService.reactivateAd(ad.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad reactivated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAds(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reactivate ad. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAd(Ad ad) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Ad'),
          content: const Text('Are you sure you want to delete this ad?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await _adService.deleteAd(ad.id);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAds(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete ad. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAdCard(Ad ad) {
    final bool isActive = ad.isActive;
    final bool isExpired = !isActive && DateTime.now().isAfter(ad.expiresAt);

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
                Text(
                  '${ad.currency} Ad',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
              'Amount: ${ad.amount.toStringAsFixed(0)} ${ad.currency}',
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive
                    ? 'Active (Expires ${_formatExpiryTime(ad.expiresAt)})'
                    : 'Expired',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (isExpired)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _reactivateAd(ad),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'Reactivate',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (isExpired) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _deleteAd(ad),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpiryTime(DateTime expiryTime) {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes}m';
    } else {
      return 'soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Ad> displayedAds =
        _showInactive ? [..._activeAds, ..._inactiveAds] : _activeAds;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Ads',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Switch(
            value: _showInactive,
            onChanged: (value) {
              setState(() {
                _showInactive = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              'Show Expired',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayedAds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.note_alt_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showInactive
                            ? 'You don\'t have any ads'
                            : 'You don\'t have any active ads',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to create ad tab
                          Navigator.pop(context);
                        },
                        child: const Text('Create New Ad'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAds,
                  child: ListView.builder(
                    itemCount: displayedAds.length,
                    itemBuilder: (context, index) {
                      return _buildAdCard(displayedAds[index]);
                    },
                  ),
                ),
    );
  }
}
