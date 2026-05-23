import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_client.dart';

class StepSyncService {
  static final instance = StepSyncService._();
  StepSyncService._();

  final _health = Health();

  Future<bool> requestPermissions() async {
    return _health.requestAuthorization([HealthDataType.STEPS]);
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.STEPS],
      startTime: midnight,
      endTime: now,
    );
    return data.fold<int>(
      0,
      (sum, p) => sum + (p.value as NumericHealthValue).numericValue.toInt(),
    );
  }

  Future<void> syncToServer() async {
    final steps = await getTodaySteps();
    if (steps == 0) return;
    await ApiClient.instance.post('/steps/sync', {
      'steps': steps,
      'syncedAt': DateTime.now().toIso8601String(),
      'source': Platform.isIOS ? 'healthkit' : 'health_connect',
      'deviceModel': 'unknown',
      'osVersion': 'unknown',
    });
  }

  // Permissions must be requested on the UI thread before the background service
  // starts syncing. Call StepSyncService.instance.requestPermissions() from a
  // screen widget (e.g., HomeScreen initState) on first launch.
  static Future<void> initialiseBackgroundService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: false,
      ),
    );
    await service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async => true;

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Initialize Supabase in the background isolate
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('supabase_url') ?? '';
      final anonKey = prefs.getString('supabase_anon_key') ?? '';
      if (url.isNotEmpty && anonKey.isNotEmpty) {
        await Supabase.initialize(url: url, anonKey: anonKey);
      }
    } catch (_) {}

    // Sync every 15 minutes
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 15));
      try {
        await StepSyncService.instance.syncToServer();
      } catch (_) {}
      return true;
    });
  }
}
