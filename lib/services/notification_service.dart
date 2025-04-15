import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;
  String? _currentToken;

  // Initialize notifications and get token
  Future<void> initialize() async {
    try {
      print('Starting notification initialization...');

      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      // Get the FCM token
      _currentToken = await _messaging.getToken();
      print('FCM Token received: $_currentToken');

      if (_currentToken != null) {
        // Try to save token if user is already logged in
        await _saveFcmToken(_currentToken!);
      } else {
        print('FCM Token is null');
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        _currentToken = newToken;
        _saveFcmToken(newToken);
      });

      // Listen for auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null && _currentToken != null) {
          print('User logged in, saving FCM token');
          _saveFcmToken(_currentToken!);
        }
      });

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
      });
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Save FCM token to Supabase
  Future<void> _saveFcmToken(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        print('Saving FCM token for user: ${user.id}');
        final response = await _supabase.from('device_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('FCM token save response: $response');
      } else {
        print('No user logged in, will save token when user logs in');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}
