import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'features/steps/step_sync_service.dart';

const _supabaseUrl = 'https://ypadjymopdbypuneqmnb.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwYWRqeW1vcGRieXB1bmVxbW5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1NTI1MTgsImV4cCI6MjA5NTEyODUxOH0.Z2Ka3K3nxUEmF6IcUiW-i5dzb8npdJ-LnpDTzGH5c6s';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('supabase_url', _supabaseUrl);
  await prefs.setString('supabase_anon_key', _supabaseAnonKey);

  runApp(const ProviderScope(child: StepUpApp()));

  // Init background service after app is running — skip in debug (native annotation not required)
  if (!kDebugMode) {
    Future.microtask(() async {
      try {
        await StepSyncService.initialiseBackgroundService();
      } catch (e) {
        debugPrint('Background service init skipped: $e');
      }
    });
  }
}
