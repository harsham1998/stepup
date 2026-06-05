import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/challenge.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/user_search_result.dart';

final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final data = await ApiClient.instance.get('/friends') as List;
  return data.map((j) => Friend.fromJson(j as Map<String, dynamic>)).toList();
});

final friendRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final data = await ApiClient.instance.get('/friends/requests') as List;
  return data.map((j) => FriendRequest.fromJson(j as Map<String, dynamic>)).toList();
});

final friendSearchProvider = FutureProvider.family<List<UserSearchResult>, String>((ref, query) async {
  if (query.length < 2) return [];
  final data = await ApiClient.instance.get('/friends/search', {'q': query}) as List;
  return data.map((j) => UserSearchResult.fromJson(j as Map<String, dynamic>)).toList();
});

final challengeFriendsLeaderboardProvider = FutureProvider.family<ChallengeLeaderboard, String>((ref, challengeId) async {
  final data = await ApiClient.instance.get('/challenges/$challengeId/leaderboard', {'filter': 'friends'}) as Map<String, dynamic>;
  return ChallengeLeaderboard.fromJson(data);
});
