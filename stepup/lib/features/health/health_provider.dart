import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_service.dart';

final healthSummaryProvider = FutureProvider<HealthSummary>((ref) async {
  await HealthService.instance.requestPermissions();
  return HealthService.instance.getTodayStats();
});
