// stepup/lib/features/gym/providers/gym_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../models/gym_plan.dart';
import '../models/gym_session.dart';

// ── Schedule provider ─────────────────────────────────────────────────────────

// Returns list of all workout plans with their user-assigned day_of_week
final userScheduleProvider = FutureProvider.autoDispose<Map<int, String>>((ref) async {
  final res = await ApiClient.instance.get('/gym/user-schedule');
  final map = res.data as Map<String, dynamic>;
  return map.map((k, v) => MapEntry(int.parse(k), v as String));
});

// ── Edit-exercises provider (per plan) ────────────────────────────────────────

class EditExercisesNotifier extends AsyncNotifier<List<EditableExercise>> {
  late String _planId;

  @override
  Future<List<EditableExercise>> build() async => [];

  Future<void> load(String planId) async {
    _planId = planId;
    state = const AsyncLoading();
    try {
      final res = await ApiClient.instance.get('/gym/plan/$planId/my-exercises');
      final list = res.data as List<dynamic>;
      state = AsyncData(list
          .map((j) => EditableExercise.fromPlanExercise(
              PlanExercise.fromJson(j as Map<String, dynamic>)))
          .toList());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reorder(int oldIndex, int newIndex) {
    final list = List<EditableExercise>.from(state.value ?? []);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (var i = 0; i < list.length; i++) {
      list[i].sortOrder = i;
    }
    state = AsyncData(list);
  }

  void remove(String id) {
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }

  void add(MasterExercise master) {
    final list = List<EditableExercise>.from(state.value ?? []);
    list.add(EditableExercise.fromMaster(master, list.length));
    state = AsyncData(list);
  }

  void updateSets(String id, int sets) {
    state = AsyncData((state.value ?? []).map((e) {
      if (e.id == id) e.sets = sets.clamp(1, 10);
      return e;
    }).toList());
  }

  Future<void> save() async {
    final list = state.value ?? [];
    await ApiClient.instance.put('/gym/plan/$_planId/my-exercises', {
      'exercises': list.map((e) => e.toJson()).toList(),
    });
    ref.invalidate(gymWeekProvider);
  }
}

final editExercisesProvider =
    AsyncNotifierProvider<EditExercisesNotifier, List<EditableExercise>>(
  EditExercisesNotifier.new,
  isAutoDispose: true,
);

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

    // Optimistically remove from local state
    final updated = GymSession(
      id: session.id,
      planId: session.planId,
      plan: session.plan,
      sessionDate: session.sessionDate,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      xpAwarded: session.xpAwarded,
      setLogs: session.setLogs
          .where((l) => !(l.exerciseId == exerciseId && l.setNumber == setNumber))
          .toList(),
    );
    state = AsyncData(updated);

    try {
      await ApiClient.instance.delete(
        '/gym/session/${session.id}/sets/$exerciseId/$setNumber',
      );
      ref.invalidate(gymWeekProvider);
    } catch (_) {
      // Rollback on error
      await init(_date);
    }
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
