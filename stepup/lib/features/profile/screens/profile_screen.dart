import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../league/providers/league_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../providers/profile_provider.dart';
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
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile', style: AppTheme.bigNum(28)),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded,
                            color: AppTheme.ink3),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar + name + league row
                  profileAsync.when(
                    loading: () =>
                        const _ProfileHeroSkeleton(),
                    error: (_, __) =>
                        const _ProfileHeroSkeleton(),
                    data: (profile) => _ProfileHero(
                      profile: profile,
                      leagueAsync: leagueAsync,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscription banner
                  subAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (sub) => sub.isPaid
                        ? _SubBadge(plan: sub.planSlug)
                        : _UpgradePrompt(
                            onTap: () => context.push(
                                '/profile/subscription')),
                  ),
                  const SizedBox(height: 20),

                  // Quick nav grid
                  Text(
                    'FEATURES',
                    style: AppTheme.label(10,
                            color: AppTheme.ink3)
                        .copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.5,
                    children: [
                      _NavTile(
                        'League',
                        Icons.military_tech_rounded,
                        AppTheme.amber,
                        () => context
                            .push('/leaderboard/league'),
                      ),
                      _NavTile(
                        'Missions',
                        Icons.task_alt_rounded,
                        AppTheme.voltLime,
                        () => context.push('/missions'),
                      ),
                      _NavTile(
                        'Rivals',
                        Icons.sports_kabaddi_rounded,
                        const Color(0xFFEF4444),
                        () => context.push('/rivals'),
                      ),
                      _NavTile(
                        'Streak',
                        Icons.local_fire_department_rounded,
                        const Color(0xFFFF6B35),
                        () => context.push('/streaks'),
                      ),
                      _NavTile(
                        'Community',
                        Icons.people_rounded,
                        const Color(0xFF8B5CF6),
                        () => context.push('/community'),
                      ),
                      _NavTile(
                        'Subscription',
                        Icons.star_rounded,
                        AppTheme.amber,
                        () => context
                            .push('/profile/subscription'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sign out
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius:
                            BorderRadius.circular(12),
                        border:
                            Border.all(color: AppTheme.border),
                      ),
                      child: Center(
                        child: Text(
                          'Sign Out',
                          style: AppTheme.label(14,
                                  color: const Color(
                                      0xFFEF4444))
                              .copyWith(
                                  fontWeight:
                                      FontWeight.w600),
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
  const _ProfileHero(
      {required this.profile, required this.leagueAsync});

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] as String? ?? 'StepUp User';
    final city = profile['city'] as String? ?? '';
    return Row(children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.voltLime.withOpacity(0.15),
          border: Border.all(
              color: AppTheme.voltLime.withOpacity(0.4),
              width: 2),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'S',
            style: AppTheme.bigNum(28, color: AppTheme.voltLime),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTheme.bigNum(22)),
              if (city.isNotEmpty)
                Text(city, style: AppTheme.label(13)),
              const SizedBox(height: 4),
              leagueAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (league) => Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      league.label,
                      style: AppTheme.label(11,
                              color: AppTheme.amber)
                          .copyWith(
                              fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Rank #${league.rankInTier}',
                      style: AppTheme.label(12)),
                ]),
              ),
            ]),
      ),
    ]);
  }
}

class _ProfileHeroSkeleton extends StatelessWidget {
  const _ProfileHeroSkeleton();

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
          ),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 120, height: 20, color: AppTheme.surface),
          const SizedBox(height: 6),
          Container(
              width: 80, height: 14, color: AppTheme.surface),
        ]),
      ]);
}

class _SubBadge extends StatelessWidget {
  final String plan;
  const _SubBadge({required this.plan});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.voltLime.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.voltLime.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.star_rounded,
              color: AppTheme.voltLime, size: 18),
          const SizedBox(width: 8),
          Text(
            '${plan[0].toUpperCase()}${plan.substring(1)} Plan',
            style: AppTheme.label(13, color: AppTheme.voltLime)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ]),
      );
}

class _UpgradePrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradePrompt({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.amber.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.bolt_rounded,
                color: AppTheme.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Upgrade to Beginner — earn coins, unlock Gold league',
                style: AppTheme.label(13),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.amber, size: 14),
          ]),
        ),
      );
}

class _NavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NavTile(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.label(13, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      );
}
