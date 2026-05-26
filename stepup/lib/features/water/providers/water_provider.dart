import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../../steps/step_sync_service.dart';

class WaterLog {
  final DateTime time;
  final double liters;
  const WaterLog({required this.time, required this.liters});
}

final waterTodayProvider = FutureProvider<List<WaterLog>>((ref) async {
  final samples = await StepSyncService.instance.getWaterSamplesForDate(DateTime.now());
  return samples.map((s) => WaterLog(
    time: s.dateFrom,
    liters: (s.value as NumericHealthValue).numericValue.toDouble(),
  )).toList();
});

final waterHistoryProvider = FutureProvider<List<double>>((ref) async {
  return StepSyncService.instance.getWaterHistoryForDays(14);
});
