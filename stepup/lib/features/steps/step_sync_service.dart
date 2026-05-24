import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_client.dart';

// Top-level entry points required by flutter_background_service iOS plugin.
// These must be top-level (not class methods) and annotated for AOT / native access.
@pragma('vm:entry-point')
Future<bool> stepSyncOnIosBackground(ServiceInstance service) async => true;

@pragma('vm:entry-point')
void stepSyncOnStart(ServiceInstance service) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('supabase_url') ?? '';
    final anonKey = prefs.getString('supabase_anon_key') ?? '';
    if (url.isNotEmpty && anonKey.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: anonKey);
    }
  } catch (_) {}

  Future.doWhile(() async {
    await Future.delayed(const Duration(minutes: 15));
    try {
      await StepSyncService.instance.syncToServer();
    } catch (_) {}
    return true;
  });
}

@pragma('vm:entry-point')
class StepSyncService {
  static final instance = StepSyncService._();
  StepSyncService._();

  final _health = Health();

  Future<bool> requestPermissions() async {
    // Request all health types so the Health screen works immediately
    try {
      return await _health.requestAuthorization([
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.EXERCISE_TIME,
        HealthDataType.WORKOUT,
        HealthDataType.FLIGHTS_CLIMBED,
        HealthDataType.APPLE_STAND_TIME,
      ]);
    } catch (_) {
      return _health.requestAuthorization([HealthDataType.STEPS]);
    }
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

  static Future<void> initialiseBackgroundService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: stepSyncOnStart,
        onBackground: stepSyncOnIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: stepSyncOnStart,
        autoStart: true,
        isForegroundMode: false,
      ),
    );
    await service.startService();
  }
}
