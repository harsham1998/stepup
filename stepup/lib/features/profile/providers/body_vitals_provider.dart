// stepup/lib/features/profile/providers/body_vitals_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/body_vitals.dart';

// Summary (latest, earliest, goal, streak, logged_today)
final bodyVitalsSummaryProvider = FutureProvider<BodyVitalsSummary>((ref) async {
  final data = await ApiClient.instance.get('/body-vitals/summary') as Map<String, dynamic>;
  return BodyVitalsSummary.fromJson(data);
});

// Full history for heatmap (last 42 days = 6 weeks)
final bodyVitalsHistoryProvider = FutureProvider<List<BodyVitalsEntry>>((ref) async {
  final data = await ApiClient.instance.get('/body-vitals/history', {'days': '42'}) as List<dynamic>;
  return data
      .map((e) => BodyVitalsEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Log action state
class VitalsLogState {
  final bool isLoading;
  final bool xpAwarded;
  final String? error;

  const VitalsLogState({
    this.isLoading = false,
    this.xpAwarded = false,
    this.error,
  });

  VitalsLogState copyWith({bool? isLoading, bool? xpAwarded, String? error}) =>
      VitalsLogState(
        isLoading: isLoading ?? this.isLoading,
        xpAwarded: xpAwarded ?? this.xpAwarded,
        error: error,
      );
}

class VitalsLogNotifier extends StateNotifier<VitalsLogState> {
  final Ref _ref;
  VitalsLogNotifier(this._ref) : super(const VitalsLogState());

  Future<void> log({
    double? weightKg,
    double? bmi,
    int? visceralFatLevel,
    double? musclePercentage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final body = <String, dynamic>{};
      if (weightKg != null)         body['weight_kg'] = weightKg;
      if (bmi != null)              body['bmi'] = bmi;
      if (visceralFatLevel != null) body['visceral_fat_level'] = visceralFatLevel;
      if (musclePercentage != null) body['muscle_percentage'] = musclePercentage;

      final result = await ApiClient.instance.post('/body-vitals/log', body)
          as Map<String, dynamic>;
      final awarded = result['xp_awarded'] as bool? ?? false;

      // Refresh summary and history so the screen shows updated data
      _ref.invalidate(bodyVitalsSummaryProvider);
      _ref.invalidate(bodyVitalsHistoryProvider);

      state = state.copyWith(isLoading: false, xpAwarded: awarded);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final vitalsLogProvider =
    StateNotifierProvider<VitalsLogNotifier, VitalsLogState>(
  (ref) => VitalsLogNotifier(ref),
);
