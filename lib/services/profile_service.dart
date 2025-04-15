import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zhet/config/supabase.dart';
import 'package:zhet/models/profile.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get the current user's profile
  Future<Profile?> getCurrentProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response =
          await _client.from('profiles').select().eq('id', user.id).single();

      return Profile.fromJson(response);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // Get a user's profile by ID
  Future<Profile?> getProfileById(String userId) async {
    try {
      final response =
          await _client.from('profiles').select().eq('id', userId).single();

      return Profile.fromJson(response);
    } catch (e) {
      print('Error getting profile by ID: $e');
      return null;
    }
  }

  // Get current user email - useful for display
  String? getCurrentUserEmail() {
    final user = _client.auth.currentUser;
    return user?.email;
  }

  // Update the current user's profile
  Future<bool> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _client.from('profiles').update(updates).eq('id', user.id);

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}
