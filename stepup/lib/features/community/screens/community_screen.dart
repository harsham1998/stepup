import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/community_provider.dart';
import '../../../shared/models/community_post.dart';
import '../../../core/theme.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
              ),
              Text('Community', style: AppTheme.bigNum(26)),
              const Spacer(),
              IconButton(
                icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppTheme.voltLime,
                    size: 24),
                onPressed: () {},
              ),
            ]),
          ),
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.voltLime)),
              error: (e, _) => Center(
                  child: Text('$e',
                      style: const TextStyle(
                          color: Colors.white))),
              data: (posts) => posts.isEmpty
                  ? Center(
                      child: Text('Be the first to flex!',
                          style: AppTheme.label(16)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      itemCount: posts.length,
                      itemBuilder: (_, i) =>
                          _PostCard(post: posts[i]),
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  static const _typeColors = {
    'flex': AppTheme.voltLime,
    'achievement': AppTheme.amber,
    'challenge_win': Color(0xFF22C55E),
    'streak_milestone': Color(0xFFFF6B35),
  };

  static const _typeLabels = {
    'flex': 'FLEX',
    'achievement': 'ACHIEVEMENT',
    'challenge_win': 'WIN',
    'streak_milestone': 'STREAK',
  };

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColors[post.type] ?? AppTheme.ink2;
    final typeLabel =
        _typeLabels[post.type] ?? post.type.toUpperCase();
    final ago = _timeAgo(post.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface2,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Center(
                  child: Text(
                    post.userName.isNotEmpty
                        ? post.userName[0].toUpperCase()
                        : '?',
                    style: AppTheme.bigNum(14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: AppTheme.label(13,
                                color: Colors.white)
                            .copyWith(
                                fontWeight: FontWeight.w600),
                      ),
                      Text(ago, style: AppTheme.label(11)),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeLabel,
                  style: AppTheme.label(9, color: typeColor)
                      .copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(post.content,
                style: AppTheme.label(14, color: Colors.white)),
            const SizedBox(height: 10),
            Row(children: [
              GestureDetector(
                onTap: () {},
                child: Row(children: [
                  Icon(
                    post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: post.likedByMe
                        ? const Color(0xFFEF4444)
                        : AppTheme.ink3,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text('${post.likes}',
                      style: AppTheme.label(12)),
                ]),
              ),
            ]),
          ]),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
