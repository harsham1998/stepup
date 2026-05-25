import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final activitiesSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {};
  final today = DateTime.now().toIso8601String().split('T')[0];
  final data = await Supabase.instance.client
      .from('activities')
      .select('activity_type, duration_minutes, calories_burned')
      .eq('user_id', userId)
      .eq('date', today);
  final summary = <String, Map<String, dynamic>>{};
  for (final row in (data as List)) {
    final type = row['activity_type'] as String;
    if (!summary.containsKey(type)) {
      summary[type] = {'sessions': 0, 'duration': 0, 'calories': 0};
    }
    summary[type]!['sessions'] = (summary[type]!['sessions'] as int) + 1;
    summary[type]!['duration'] =
        (summary[type]!['duration'] as int) + ((row['duration_minutes'] as int?) ?? 0);
    summary[type]!['calories'] =
        (summary[type]!['calories'] as int) + ((row['calories_burned'] as int?) ?? 0);
  }
  return summary;
});

final activitiesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final today = DateTime.now().toIso8601String().split('T')[0];
  final data = await Supabase.instance.client
      .from('activities')
      .select('*')
      .eq('user_id', userId)
      .eq('date', today)
      .order('logged_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});
