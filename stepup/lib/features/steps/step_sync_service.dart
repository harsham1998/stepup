import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_client.dart';

class HealthDaySummary {
  final int steps, calories, activeMins, floors;
  final double distanceKm;
  const HealthDaySummary({
    required this.steps,
    required this.distanceKm,
    required this.calories,
    required this.activeMins,
    required this.floors,
  });
}

class HealthWorkout {
  final String type;
  final DateTime startTime, endTime;
  final int durationMins, calories;
  final double distanceKm;
  const HealthWorkout({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationMins,
    required this.calories,
    required this.distanceKm,
  });
}

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
    try {
      final types = [
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
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.WATER,
      ];
      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ_WRITE,
      ];
      return await _health.requestAuthorization(types, permissions: permissions);
    } catch (_) {
      return _health.requestAuthorization([HealthDataType.STEPS]);
    }
  }

  Future<int> getTodaySteps() async {
    return getStepsForDate(DateTime.now());
  }

  Future<int> getStepsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      // getTotalStepsInInterval uses HealthKit's HKStatisticsQuery — same
      // aggregation the Health app uses, so Watch + iPhone steps are
      // deduplicated correctly and totals match exactly.
      return await _health.getTotalStepsInInterval(start, end) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<HealthDaySummary> getDaySummary(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final results = await Future.wait([
        getStepsForDate(date),
        _preferredSourceTotalDouble(HealthDataType.DISTANCE_WALKING_RUNNING, start, end),
        _preferredSourceTotalDouble(HealthDataType.ACTIVE_ENERGY_BURNED, start, end),
        _preferredSourceTotalDouble(HealthDataType.EXERCISE_TIME, start, end),
        _preferredSourceTotalDouble(HealthDataType.FLIGHTS_CLIMBED, start, end),
      ]);

      return HealthDaySummary(
        steps: results[0] as int,
        distanceKm: (results[1] as double) / 1000, // meters → km
        calories: (results[2] as double).round(),
        activeMins: (results[3] as double).round(),
        floors: (results[4] as double).round(),
      );
    } catch (_) {
      final steps = await getStepsForDate(date);
      return HealthDaySummary(
        steps: steps,
        distanceKm: steps * 0.00076,
        calories: (steps * 0.053).round(),
        activeMins: (steps / 150).round(),
        floors: 0,
      );
    }
  }

  // Returns the total for a type from the preferred source.
  // Prefers Apple Watch (source name contains "watch") to match what
  // the Health app shows when a Watch is paired. Falls back to the
  // source with the highest total (avoids summing Watch + iPhone).
  Future<int> _preferredSourceTotal(
      HealthDataType type, DateTime start, DateTime end) async {
    final data = await _health.getHealthDataFromTypes(
      types: [type], startTime: start, endTime: end);
    if (data.isEmpty) return 0;
    return _pickPreferredSource(data).round();
  }

  Future<double> _preferredSourceTotalDouble(
      HealthDataType type, DateTime start, DateTime end) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [type], startTime: start, endTime: end);
      if (data.isEmpty) return 0;
      return _pickPreferredSource(data);
    } catch (_) {
      return 0;
    }
  }

  double _pickPreferredSource(List<HealthDataPoint> data) {
    // Group totals by sourceId, keep source names for Watch detection
    final Map<String, double> totals = {};
    final Map<String, String> names = {};
    for (final p in data) {
      final v = (p.value as NumericHealthValue).numericValue.toDouble();
      totals[p.sourceId] = (totals[p.sourceId] ?? 0) + v;
      names[p.sourceId] = p.sourceName;
    }
    // Prefer Watch source — matches Health app's preferred-source algorithm
    for (final id in totals.keys) {
      if ((names[id] ?? '').toLowerCase().contains('watch')) {
        return totals[id]!;
      }
    }
    // No Watch found: use highest single source to avoid double-counting
    return totals.values.reduce((a, b) => a > b ? a : b);
  }

  Future<List<HealthWorkout>> getWorkoutsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: end,
      );
      return data.map((p) {
        final w = p.value as WorkoutHealthValue;
        return HealthWorkout(
          type: w.workoutActivityType.name,
          startTime: p.dateFrom,
          endTime: p.dateTo,
          durationMins: p.dateTo.difference(p.dateFrom).inMinutes,
          calories: w.totalEnergyBurned?.toInt() ?? 0,
          distanceKm: (w.totalDistance ?? 0) / 1000,
        );
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (_) {
      return [];
    }
  }

  Future<double> getSleepHoursForDate(DateTime date) async {
    // Night starting the previous day at 6 PM through the given date at noon.
    // Queries all actual sleep stage types — modern Apple Watch records DEEP,
    // LIGHT (core), and REM instead of the generic SLEEP_ASLEEP aggregate.
    // These types don't overlap on the timeline, so summing them is safe.
    final start = DateTime(date.year, date.month, date.day - 1, 18);
    final end = DateTime(date.year, date.month, date.day, 12);
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_REM,
        ],
        startTime: start,
        endTime: end,
      );
      final totalMins = data.fold<double>(
        0,
        (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes,
      );
      return totalMins / 60.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<int> getAverageHeartRateForDay(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return 0;
      final total = data.fold<double>(
        0, (sum, p) => sum + (p.value as NumericHealthValue).numericValue.toDouble());
      return (total / data.length).round();
    } catch (_) {
      return 0;
    }
  }

  Future<double> getWaterLitersForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: start,
        endTime: end,
      );
      return data.fold<double>(
        0,
        (sum, p) => sum + (p.value as NumericHealthValue).numericValue.toDouble(),
      );
    } catch (_) {
      return 0.0;
    }
  }

  Future<List<int>> getWeekSteps() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final futures = List.generate(7, (i) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      return day.isAfter(now) ? Future.value(0) : getStepsForDate(day);
    });
    return Future.wait(futures);
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

  Future<List<HealthDataPoint>> getWaterSamplesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: start,
        endTime: end,
      );
      data.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
      return data;
    } catch (_) {
      return [];
    }
  }

  Future<bool> logWater(double liters) async {
    final now = DateTime.now();
    try {
      return await _health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: now,
        endTime: now,
        unit: HealthDataUnit.LITER,
      );
    } catch (_) {
      return false;
    }
  }

  Future<List<double>> getWaterHistoryForDays(int days) async {
    final futures = List.generate(days, (i) {
      final date = DateTime.now().subtract(Duration(days: days - 1 - i));
      return getWaterLitersForDate(date);
    });
    return Future.wait(futures);
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
