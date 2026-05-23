import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'features/notifications/notification_service.dart';
import 'features/steps/step_sync_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase not configured yet — set up via flutterfire configure
    debugPrint('Firebase init skipped: $e');
  }
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://placeholder.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'placeholder-anon-key');
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  // Persist credentials for background isolate (flutter_background_service)
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('supabase_url', supabaseUrl);
  await prefs.setString('supabase_anon_key', supabaseAnonKey);
  try {
    await NotificationService.initialise();
  } catch (e) {
    debugPrint('Notifications init skipped: $e');
  }
  await StepSyncService.initialiseBackgroundService();
  runApp(const ProviderScope(child: StepUpApp()));
}
