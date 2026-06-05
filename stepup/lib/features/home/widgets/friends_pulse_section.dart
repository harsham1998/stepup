import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../shared/models/friend_activity.dart';
import '../../social/providers/social_provider.dart';

class FriendsPulseSection extends ConsumerWidget {
  const FriendsPulseSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(socialActivityFeedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.voltLime,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'FRIENDS PULSE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink2,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/friends'),
                child: Text('Manage →',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.voltLime)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        feedAsync.when(
          data: (activities) => activities.isEmpty
              ? _NoFriendsPrompt()
              : SizedBox(
                  height: 82,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activities.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _ActivityCard(activity: activities[i]),
                  ),
                ),
          loading: () => SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, _) => _SkeletonCard(),
            ),
          ),
          error: (err, st) => _NoFriendsPrompt(),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final FriendActivity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _eventInfo(activity);

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (activity.friendAvatar != null)
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(activity.friendAvatar!),
                  backgroundColor: AppTheme.surface2,
                )
              else
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(
                    activity.friendName.isNotEmpty ? activity.friendName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.friendName,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _timeAgo(activity.occurredAt),
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.ink3),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _eventInfo(FriendActivity a) {
    switch (a.type) {
      case 'battle_lost':
        final friendSteps = a.meta['friend_steps'] as int? ?? 0;
        final mySteps = a.meta['my_steps'] as int? ?? 0;
        return (
          Icons.emoji_events_rounded,
          AppTheme.amber,
          'Beat you by ${_fmt(friendSteps - mySteps)} steps',
        );
      case 'league_overtake':
        final gap = a.meta['gap'] as int? ?? 0;
        return (
          Icons.trending_up_rounded,
          AppTheme.voltLime,
          'Overtook you by $gap XP',
        );
      case 'streak_milestone':
        final days = a.meta['streak_days'] as int? ?? 0;
        return (
          Icons.local_fire_department_rounded,
          const Color(0xFFFF6B35),
          '$days day streak!',
        );
      default:
        return (Icons.bolt_rounded, AppTheme.ink2, 'Activity');
    }
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 82,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
    );
  }
}

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Text(
          'Add friends to see their activity',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.ink2),
        ),
      ),
    );
  }
}

class _NoFriendsPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/friends'),
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: Text(
            '👥 Add friends to see their pulse here →',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.ink2),
          ),
        ),
      ),
    );
  }
}
