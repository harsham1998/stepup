class StepSyncService {
  static final instance = StepSyncService._();
  StepSyncService._();

  Future<int> getTodaySteps() async {
    // Stub — returns 0 until Task 8 wires up HealthKit/Health Connect
    return 0;
  }
}
