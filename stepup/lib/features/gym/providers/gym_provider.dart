// stepup/lib/features/gym/providers/gym_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../models/gym_plan.dart';
import '../models/gym_session.dart';

// ── Week plan (read-only, refreshed on invalidate) ─────────────────────────

final gymWeekProvider = FutureProvider<List<WeekDay>>((ref) async {
  final data = await ApiClient.instance.get('/gym/week');
  return (data as List)
      .map((e) => WeekDay.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Session for a specific date (mutable — supports logging sets) ──────────

class GymSessionNotifier extends AsyncNotifier<GymSession?> {
  late String _date;

  @override
  Future<GymSession?> build() async => null; // initialized via init()

  Future<void> init(String date) async {
    _date = date;
    state = const AsyncLoading();
    try {
      final data = await ApiClient.instance.get('/gym/session/$date');
      state = AsyncData(GymSession.fromJson(data as Map<String, dynamic>));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logSet({
    required String exerciseId,
    required int setNumber,
    double? weightKg,
    int? reps,
    int? durationSecs,
  }) async {
    final session = state.value;
    if (session == null) return;

    final data = await ApiClient.instance.post(
      '/gym/session/${session.id}/sets',
      {
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'duration_secs': durationSecs,
      }..removeWhere((_, v) => v == null),
    );

    final newLog = SetLog.fromJson(data as Map<String, dynamic>);
    final updated = GymSession(
      id: session.id,
      planId: session.planId,
      plan: session.plan,
      sessionDate: session.sessionDate,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      xpAwarded: session.xpAwarded,
      setLogs: [
        ...session.setLogs.where(
          (l) => !(l.exerciseId == exerciseId && l.setNumber == setNumber),
        ),
        newLog,
      ],
    );
    state = AsyncData(updated);
    ref.invalidate(gymWeekProvider);
  }

  Future<void> deleteSet({
    required String exerciseId,
    required int setNumber,
  }) async {
    final session = state.value;
    if (session == null) return;

    await ApiClient.instance.delete(
      '/gym/session/${session.id}/sets/$exerciseId/$setNumber',
    );
    // Re-fetch to sync server state
    await init(_date);
  }

  Future<int> completeSession() async {
    final session = state.value;
    if (session == null) return 0;

    final data = await ApiClient.instance
        .post('/gym/session/${session.id}/complete', {});
    final xp = (data['xp_awarded'] as num? ?? 0).toInt();

    final updated = GymSession(
      id: session.id,
      planId: session.planId,
      plan: session.plan,
      sessionDate: session.sessionDate,
      startedAt: session.startedAt,
      completedAt: DateTime.now().toIso8601String(),
      xpAwarded: xp,
      setLogs: session.setLogs,
    );
    state = AsyncData(updated);
    ref.invalidate(gymWeekProvider);
    return xp;
  }
}

final gymSessionProvider =
    AsyncNotifierProvider<GymSessionNotifier, GymSession?>(
  GymSessionNotifier.new,
  isAutoDispose: true,
);
