import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://kdfpryavfzmdshmgwmxo.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkZnByeWF2ZnptZHNobWd3bXhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwNDc3NTQsImV4cCI6MjA1OTYyMzc1NH0.sqvsTrBPG9yyz6ePmMso1AG4jHsV_GHE_ImxyEmFmAo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
