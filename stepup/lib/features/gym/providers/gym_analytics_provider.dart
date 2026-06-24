// stepup/lib/features/gym/providers/gym_analytics_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../models/gym_analytics.dart';

final gymStatsProvider = FutureProvider.autoDispose<GymStats>((ref) async {
  final res = await ApiClient.instance.get('/gym/stats');
  return GymStats.fromJson(res.data as Map<String, dynamic>);
});

final gymHistoryProvider = FutureProvider.autoDispose<List<SessionHistoryItem>>((ref) async {
  final res = await ApiClient.instance.get('/gym/history?weeks=8');
  final list = res.data as List<dynamic>;
  return list.map((j) => SessionHistoryItem.fromJson(j as Map<String, dynamic>)).toList();
});

// Aggregates raw set logs per exercise into max-weight-per-session points
final exerciseProgressionProvider = FutureProvider.autoDispose.family<List<ExerciseProgressPoint>, String>(
  (ref, exerciseId) async {
    final res = await ApiClient.instance.get('/gym/exercise/$exerciseId/history');
    final list = res.data as List<dynamic>;

    // Group by session_date, find max weight and corresponding reps
    final byDate = <String, List<Map<String, dynamic>>>{};
    for (final item in list) {
      final m = item as Map<String, dynamic>;
      final date = m['session_date'] as String? ?? '';
      byDate.putIfAbsent(date, () => []).add(m);
    }

    final points = byDate.entries.map((e) {
      final sets = e.value;
      double maxW = 0;
      int repsAtMax = 0;
      for (final s in sets) {
        final w = (s['weight_kg'] as num?)?.toDouble() ?? 0.0;
        if (w > maxW) {
          maxW = w;
          repsAtMax = (s['reps'] as num?)?.toInt() ?? 0;
        }
      }
      return ExerciseProgressPoint(date: e.key, maxWeightKg: maxW, maxReps: repsAtMax);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return points;
  },
);
