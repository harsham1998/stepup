import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../league/providers/league_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/league_status.dart';
import '../../../core/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final leagueAsync = ref.watch(leagueStatusProvider);
    final subAsync = ref.watch(mySubscriptionProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Me', style: AppTheme.bigNum(32)),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded,
                            color: AppTheme.ink3),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar + name + sub row
                  profileAsync.when(
                    loading: () => const _ProfileHeroSkeleton(),
                    error: (_, __) => const _ProfileHeroSkeleton(),
                    data: (profile) => _ProfileHero(
                      profile: profile,
                      leagueAsync: leagueAsync,
                      subAsync: subAsync,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats row: Streak | Challenges | Coins
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(children: [
                      _StatBox(label: 'Streak', value: '0'),
                      _Divider(),
                      _StatBox(label: 'Challenges', value: '0'),
                      _Divider(),
                      subAsync.when(
                        loading: () =>
                            _StatBox(label: 'Coins', value: '0'),
                        error: (_, __) =>
                            _StatBox(label: 'Coins', value: '0'),
                        data: (_) => _StatBox(label: 'Coins', value: '0'),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  Divider(
                      color: AppTheme.border, thickness: 1, height: 1),
                  const SizedBox(height: 20),

                  // Recent badges section
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent badges',
                          style: AppTheme.label(13, color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile/achievements'),
                          child: Text('See all',
                              style: AppTheme.label(12,
                                  color: AppTheme.voltLime)),
                        ),
                      ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 72,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _BadgeCard(emoji: '🔥', label: '7-day streak'),
                        _BadgeCard(emoji: '👟', label: 'First 10k'),
                        _BadgeCard(emoji: '🏆', label: 'Winner'),
                        _BadgeCard(emoji: '⚡', label: 'Speed run'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings menu
                  _MenuItem(
                    label: 'Activity history',
                    icon: Icons.history_rounded,
                    onTap: () => context.push('/activities'),
                  ),
                  _MenuItem(
                    label: 'Achievements',
                    icon: Icons.emoji_events_rounded,
                    onTap: () => context.push('/profile/achievements'),
                  ),
                  _MenuItem(
                    label: 'Reputation',
                    icon: Icons.shield_rounded,
                    onTap: () => context.push('/profile/reputation'),
                  ),
                  _MenuItem(
                    label: 'Level & XP',
                    icon: Icons.bolt_rounded,
                    onTap: () => context.push('/profile/xp'),
                  ),
                  _MenuItem(
                    label: 'Friends · 14',
                    icon: Icons.people_rounded,
                    onTap: () => context.push('/community'),
                  ),
                  _MenuItem(
                    label: 'Plan & billing',
                    icon: Icons.credit_card_rounded,
                    onTap: () => context.push('/profile/subscription'),
                  ),
                  _MenuItem(
                    label: 'Notifications',
                    icon: Icons.notifications_none_rounded,
                    onTap: () => context.push('/notifications'),
                  ),
                  _MenuItem(
                    label: 'Help & support',
                    icon: Icons.help_outline_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  // Sign out
                  GestureDetector(
                    onTap: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Center(
                        child: Text(
                          'Sign Out',
                          style: AppTheme.label(14,
                                  color: const Color(0xFFEF4444))
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final Map<String, dynamic> profile;
  final AsyncValue<LeagueStatus> leagueAsync;
  final AsyncValue<dynamic> subAsync;
  const _ProfileHero({
    required this.profile,
    required this.leagueAsync,
    required this.subAsync,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] as String? ?? 'StepUp User';
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.voltLime.withValues(alpha: 0.12),
          border: Border.all(
              color: AppTheme.voltLime.withValues(alpha: 0.5), width: 2),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'S',
            style: AppTheme.bigNum(24, color: AppTheme.voltLime),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: AppTheme.bigNum(22)),
          const SizedBox(height: 4),
          Text(
            'Joined Apr 2024 · India',
            style: AppTheme.label(12, color: AppTheme.ink2),
          ),
          const SizedBox(height: 6),
          subAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => _SubChip(label: 'Free'),
            data: (sub) {
              final isPaid = sub?.isPaid as bool? ?? false;
              final plan = sub?.planSlug as String? ?? 'free';
              return _SubChip(
                  label: isPaid
                      ? '${plan[0].toUpperCase()}${plan.substring(1)}'
                      : 'Free');
            },
          ),
        ]),
      ),
    ]);
  }
}

class _SubChip extends StatelessWidget {
  final String label;
  const _SubChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.voltLime.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.voltLime.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTheme.label(11, color: AppTheme.voltLime)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _ProfileHeroSkeleton extends StatelessWidget {
  const _ProfileHeroSkeleton();

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
          ),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 120, height: 20, color: AppTheme.surface),
          const SizedBox(height: 6),
          Container(width: 80, height: 14, color: AppTheme.surface),
        ]),
      ]);
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: AppTheme.bigNum(20)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.label(11, color: AppTheme.ink3)),
        ]),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 32, color: AppTheme.border);
}

class _BadgeCard extends StatelessWidget {
  final String emoji, label;
  const _BadgeCard({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.label(9, color: AppTheme.ink2),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
      );
}

class _MenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
                bottom: BorderSide(
                    color: AppTheme.border.withValues(alpha: 0.5))),
          ),
          child: Row(children: [
            Icon(icon, color: AppTheme.ink2, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTheme.label(14, color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.ink3, size: 13),
          ]),
        ),
      );
}
