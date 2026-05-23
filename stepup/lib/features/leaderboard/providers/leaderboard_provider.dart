import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/leaderboard_entry.dart';

final globalLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final data = await ApiClient.instance.get('/leaderboard/global') as Map<String, dynamic>;
  final entries = data['entries'] as List? ?? [];
  return entries.map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>)).toList();
});

final friendsLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final data = await ApiClient.instance.get('/leaderboard/friends') as Map<String, dynamic>;
  final entries = data['entries'] as List? ?? [];
  return entries.map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>)).toList();
});
