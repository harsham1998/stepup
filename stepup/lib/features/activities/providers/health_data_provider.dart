import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../steps/step_sync_service.dart';

// Notifier that holds the currently selected date
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void setDate(DateTime d) => state = DateTime(d.year, d.month, d.day);
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

final healthDaySummaryProvider =
    FutureProvider.family<HealthDaySummary, DateTime>((ref, date) async {
  return StepSyncService.instance.getDaySummary(date);
});

final healthWorkoutsProvider =
    FutureProvider.family<List<HealthWorkout>, DateTime>((ref, date) async {
  return StepSyncService.instance.getWorkoutsForDate(date);
});

final weekStepsProvider = FutureProvider<List<int>>((ref) async {
  return StepSyncService.instance.getWeekSteps();
});

// Selected workout for detail view
class SelectedWorkoutNotifier extends Notifier<HealthWorkout?> {
  @override
  HealthWorkout? build() => null;
  void select(HealthWorkout w) => state = w;
}

final selectedWorkoutProvider =
    NotifierProvider<SelectedWorkoutNotifier, HealthWorkout?>(
        SelectedWorkoutNotifier.new);

// Workout notes — saved locally via SharedPreferences (keyed by startTime ISO)
final workoutNotesProvider =
    FutureProvider.family<String, String>((ref, key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('workout_note_$key') ?? '';
});

Future<void> saveWorkoutNote(String key, String note) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('workout_note_$key', note);
}

// HealthKit workouts grouped by our app categories for a date
final heartRateProvider = FutureProvider.family<int, DateTime>((ref, date) async {
  return StepSyncService.instance.getAverageHeartRateForDay(date);
});

final healthCategoryProvider =
    FutureProvider.family<Map<String, CategoryStats>, DateTime>(
        (ref, date) async {
  final workouts = await StepSyncService.instance.getWorkoutsForDate(date);
  final summary = await StepSyncService.instance.getDaySummary(date);

  final result = <String, CategoryStats>{};

  // Steps / Walking
  if (summary.steps > 0) {
    result['walk'] = CategoryStats(
        sessions: 1,
        totalMins: summary.activeMins,
        totalKm: summary.distanceKm,
        steps: summary.steps);
  }

  for (final w in workouts) {
    final cat = _categorize(w.type);
    if (cat == 'walk') continue; // walking already covered by steps
    final prev = result[cat] ??
        const CategoryStats(
            sessions: 0, totalMins: 0, totalKm: 0, steps: 0);
    result[cat] = CategoryStats(
        sessions: prev.sessions + 1,
        totalMins: prev.totalMins + w.durationMins,
        totalKm: prev.totalKm + w.distanceKm,
        steps: prev.steps);
  }

  return result;
});

class CategoryStats {
  final int sessions, totalMins, steps;
  final double totalKm;
  const CategoryStats(
      {required this.sessions,
      required this.totalMins,
      required this.totalKm,
      required this.steps});
}

String _categorize(String type) {
  final t = type.toLowerCase();
  if (t.contains('run')) return 'run';
  if (t.contains('walk')) return 'walk';
  if (t.contains('cycl') || t.contains('bike')) return 'cycle';
  if (t.contains('swim')) return 'swim';
  if (t.contains('yoga') || t.contains('mind_and_body') ||
      t.contains('mindfulness')) return 'yoga';
  if (t.contains('strength') || t.contains('functional') ||
      t.contains('gym') || t.contains('cross') ||
      t.contains('hiit') || t.contains('high_intensity')) return 'gym';
  if (t.contains('sport') || t.contains('soccer') ||
      t.contains('basketball') || t.contains('tennis')) return 'sport';
  return 'other';
}

// Logged activities from Supabase for a given date
final loggedActivitiesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>(
        (ref, date) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final data = await Supabase.instance.client
      .from('activities')
      .select('*')
      .eq('user_id', userId)
      .eq('date', dateStr)
      .order('logged_at', ascending: true);
  return List<Map<String, dynamic>>.from(data as List);
});
