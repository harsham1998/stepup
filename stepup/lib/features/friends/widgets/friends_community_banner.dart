import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../providers/friends_provider.dart';
import '../models/friend.dart';

class FriendsCommunityBanner extends ConsumerWidget {
  const FriendsCommunityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);
    final pendingCount = requestsAsync.whenOrNull(data: (list) => list.length) ?? 0;

    return GestureDetector(
      onTap: () => context.push('/friends'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.voltLime.withValues(alpha: 0.25),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('FRIENDS', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.ink2, letterSpacing: 1.2)),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                    ),
                    child: Text('$pendingCount request${pendingCount > 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                            fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.amber)),
                  ),
                ],
              ]),
              const SizedBox(height: 8),
              friendsAsync.when(
                loading: () => const SizedBox(height: 28),
                error: (err, st) => Text('Add friends →',
                    style: AppTheme.label(12, color: AppTheme.voltLime)),
                data: (friends) {
                  if (friends.isEmpty) {
                    return Text('Find friends →',
                        style: AppTheme.label(12, color: AppTheme.voltLime));
                  }
                  return _AvatarRow(friends: friends.take(5).toList());
                },
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Text('See All →', style: AppTheme.label(12, color: AppTheme.voltLime)),
        ]),
      ),
    );
  }
}

class _AvatarRow extends StatelessWidget {
  final List<Friend> friends;
  const _AvatarRow({required this.friends});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        children: List.generate(friends.length + 1, (i) {
          if (i == friends.length) {
            return Positioned(
              left: i * 18.0,
              child: GestureDetector(
                onTap: () => context.push('/friends'),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.bg, width: 1.5),
                  ),
                  child: const Icon(Icons.add_rounded, size: 14, color: AppTheme.voltLime),
                ),
              ),
            );
          }
          final f = friends[i];
          final url = f.avatarUrl;
          final name = f.name;
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bg, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: url != null ? NetworkImage(url) : null,
                backgroundColor: AppTheme.surface2,
                child: url == null
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppTheme.voltLime))
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
