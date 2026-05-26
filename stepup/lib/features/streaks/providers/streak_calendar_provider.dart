import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/streak_calendar_day.dart';

final streakCalendarProvider = FutureProvider<List<StreakCalendarDay>>((ref) async {
  final data = await ApiClient.instance.get('/streaks/calendar?days=60') as List<dynamic>;
  return data.map((e) => StreakCalendarDay.fromJson(e as Map<String, dynamic>)).toList();
});
