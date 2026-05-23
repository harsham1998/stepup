import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://placeholder.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'placeholder-anon-key'),
  );
  try {
    await NotificationService.initialise();
  } catch (e) {
    debugPrint('Notifications init skipped: $e');
  }
  await StepSyncService.initialiseBackgroundService();
  runApp(const ProviderScope(child: StepUpApp()));
}
