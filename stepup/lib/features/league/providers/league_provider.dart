import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/league_status.dart';

final leagueStatusProvider = FutureProvider<LeagueStatus>((ref) async {
  final data = await ApiClient.instance.get('/leagues/me') as Map<String, dynamic>;
  return LeagueStatus.fromJson(data);
});

final leagueStandingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiClient.instance.get('/leagues/standings') as Map<String, dynamic>;
});
