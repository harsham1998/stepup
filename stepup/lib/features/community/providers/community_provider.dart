import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/community_post.dart';

final communityFeedProvider = FutureProvider<List<CommunityPost>>((ref) async {
  final data = await ApiClient.instance.get('/community/feed') as List;
  return data.map((j) => CommunityPost.fromJson(j as Map<String, dynamic>)).toList();
});
