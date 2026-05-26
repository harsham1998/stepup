import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/leaderboard_entry.dart';

class LeaderboardResult {
  final List<LeaderboardEntry> entries;
  final int myRank;
  final int mySteps;

  const LeaderboardResult({
    required this.entries,
    required this.myRank,
    required this.mySteps,
  });

  int get total => entries.length;
  int get cutoffRank => total > 0 ? (total * 0.5).ceil().clamp(1, total) : 1;
  int get maxSteps => entries.isEmpty ? 0 : entries.first.steps;
  double get myProgress => total > 0 ? (1.0 - myRank / total).clamp(0.0, 1.0) : 0.0;
  int get myTopPct => total > 0 ? (myRank * 100 / total).round().clamp(1, 100) : 0;
}

final globalLeaderboardProvider = FutureProvider<LeaderboardResult>((ref) async {
  final data = await ApiClient.instance.get('/leaderboard/global') as Map<String, dynamic>;
  final entries = (data['entries'] as List? ?? [])
      .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
      .toList();
  final mr = data['myRank'] as Map<String, dynamic>?;
  return LeaderboardResult(
    entries: entries,
    myRank: (mr?['rank'] as num?)?.toInt() ?? 0,
    mySteps: (mr?['steps'] as num?)?.toInt() ?? 0,
  );
});

final friendsLeaderboardProvider = FutureProvider<LeaderboardResult>((ref) async {
  final data = await ApiClient.instance.get('/leaderboard/friends') as Map<String, dynamic>;
  final entries = (data['entries'] as List? ?? [])
      .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
      .toList();
  return LeaderboardResult(entries: entries, myRank: 0, mySteps: 0);
});

final cityLeaderboardProvider = FutureProvider<LeaderboardResult>((ref) async {
  final data = await ApiClient.instance.get('/leaderboard/city/all') as Map<String, dynamic>;
  final entries = (data['entries'] as List? ?? [])
      .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
      .toList();
  return LeaderboardResult(entries: entries, myRank: 0, mySteps: 0);
});
