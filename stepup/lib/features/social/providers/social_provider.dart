import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/friend_activity.dart';

final socialActivityFeedProvider = FutureProvider<List<FriendActivity>>((ref) async {
  final data = await ApiClient.instance.get('/social/activity-feed') as List;
  return data.map((j) => FriendActivity.fromJson(j as Map<String, dynamic>)).toList();
});

final friendsLeagueStandingsProvider = FutureProvider<FriendsStandings>((ref) async {
  final data = await ApiClient.instance.get('/leagues/friends-standings') as Map<String, dynamic>;
  return FriendsStandings.fromJson(data);
});
