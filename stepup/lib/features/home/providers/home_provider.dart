import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../steps/step_sync_service.dart';

final dailyStepsProvider = FutureProvider<int>((ref) async {
  return StepSyncService.instance.getTodaySteps();
});
