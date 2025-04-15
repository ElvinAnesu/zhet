import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zhet/config/supabase.dart';
import 'package:zhet/models/profile.dart';
import 'package:zhet/services/profile_service.dart';

class Ad {
  final String id;
  final String userId;
  final String currency;
  final double amount;
  final double exchangeRate;
  final String location;
  final String description;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  // Additional data for UI display
  Profile? userProfile;
  bool isCurrentUser = false;

  Ad({
    required this.id,
    required this.userId,
    required this.currency,
    required this.amount,
    required this.exchangeRate,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    this.userProfile,
    this.isCurrentUser = false,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'],
      userId: json['user_id'],
      currency: json['currency'],
      amount:
          json['amount'] is int ? json['amount'].toDouble() : json['amount'],
      exchangeRate: json['exchange_rate'] is int
          ? json['exchange_rate'].toDouble()
          : json['exchange_rate'],
      location: json['location'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'currency': currency,
      'amount': amount,
      'exchange_rate': exchangeRate,
      'location': location,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  // Helper method to format relative time (e.g., "2 hours ago")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper to format the exchange rate properly
  String getFormattedRate() {
    return '1:$exchangeRate';
  }
}

class AdService {
  final SupabaseClient _client = SupabaseConfig.client;
  final ProfileService _profileService = ProfileService();

  // Create a new ad
  Future<bool> createAd({
    required String currency,
    required double amount,
    required double exchangeRate,
    required String location,
    required String description,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('ads').insert({
        'user_id': user.id,
        'currency': currency,
        'amount': amount,
        'exchange_rate': exchangeRate,
        'location': location,
        'description': description,
      });

      return true;
    } catch (e) {
      print('Error creating ad: $e');
      return false;
    }
  }

  // Get all active ads for a specific currency
  Future<List<Ad>> getActiveAdsByCurrency(String currency) async {
    try {
      final currentUser = _client.auth.currentUser;

      // Get active ads for the specified currency
      final response = await _client
          .from('ads')
          .select()
          .eq('currency', currency)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      // Convert to Ad objects
      List<Ad> ads = response.map<Ad>((json) => Ad.fromJson(json)).toList();

      // Load profile data for each ad
      for (var ad in ads) {
        try {
          // Check if this is the current user's ad
          if (currentUser != null && ad.userId == currentUser.id) {
            ad.isCurrentUser = true;
          }

          // Get the user profile
          final profile = await _profileService.getProfileById(ad.userId);
          if (profile != null) {
            ad.userProfile = profile;
          }
        } catch (e) {
          print('Error loading profile for ad ${ad.id}: $e');
        }
      }

      return ads;
    } catch (e) {
      print('Error getting ads: $e');
      return [];
    }
  }

  // Get current user's ads
  Future<List<Ad>> getCurrentUserAds({bool includeInactive = false}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      var query = _client.from('ads').select().eq('user_id', user.id);

      if (!includeInactive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      // Convert to Ad objects
      List<Ad> ads = response.map<Ad>((json) => Ad.fromJson(json)).toList();

      // Mark all as current user's ads
      for (var ad in ads) {
        ad.isCurrentUser = true;

        // Get the user profile
        final profile = await _profileService.getProfileById(ad.userId);
        if (profile != null) {
          ad.userProfile = profile;
        }
      }

      return ads;
    } catch (e) {
      print('Error getting user ads: $e');
      return [];
    }
  }

  // Reactivate an ad (extends the expiry by 24 hours)
  Future<bool> reactivateAd(String adId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      await _client
          .from('ads')
          .update({
            'is_active': true,
            'expires_at': expiresAt.toIso8601String(),
            'created_at': now.toIso8601String(), // Reset the created time
          })
          .eq('id', adId)
          .eq('user_id', user.id); // Ensure user owns the ad

      return true;
    } catch (e) {
      print('Error reactivating ad: $e');
      return false;
    }
  }

  // Update an existing ad
  Future<bool> updateAd({
    required String adId,
    String? currency,
    double? amount,
    double? exchangeRate,
    String? location,
    String? description,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{};
      if (currency != null) updates['currency'] = currency;
      if (amount != null) updates['amount'] = amount;
      if (exchangeRate != null) updates['exchange_rate'] = exchangeRate;
      if (location != null) updates['location'] = location;
      if (description != null) updates['description'] = description;

      await _client
          .from('ads')
          .update(updates)
          .eq('id', adId)
          .eq('user_id', user.id); // Ensure user owns the ad

      return true;
    } catch (e) {
      print('Error updating ad: $e');
      return false;
    }
  }

  // Delete an ad
  Future<bool> deleteAd(String adId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client
          .from('ads')
          .delete()
          .eq('id', adId)
          .eq('user_id', user.id); // Ensure user owns the ad

      return true;
    } catch (e) {
      print('Error deleting ad: $e');
      return false;
    }
  }
}
