import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/community_post.dart';

final communityFeedProvider = FutureProvider<List<CommunityPost>>((ref) async {
  final data = await ApiClient.instance.get('/community/feed') as List;
  return data.map((j) => CommunityPost.fromJson(j as Map<String, dynamic>)).toList();
});

class CreatePostState {
  final bool isLoading;
  final String? error;
  final bool success;
  const CreatePostState({this.isLoading = false, this.error, this.success = false});
  CreatePostState copyWith({bool? isLoading, String? error, bool? success}) =>
      CreatePostState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => const CreatePostState();

  Future<void> submit({
    required String type,
    required String content,
    required String visibility,
    List<String> mediaUrls = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await ApiClient.instance.post('/community/posts', {
        'type': type,
        'content': content,
        'visibility': visibility,
        'media_urls': mediaUrls,
      });
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const CreatePostState();
}

final createPostProvider =
    NotifierProvider<CreatePostNotifier, CreatePostState>(
  CreatePostNotifier.new,
);
