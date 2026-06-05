import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../challenges/providers/challenges_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/providers/xp_level_provider.dart';
import '../../league/providers/league_provider.dart';
import '../../../shared/models/xp_level.dart';
import '../../activities/providers/health_data_provider.dart';
import '../../missions/providers/health_missions_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../rivals/providers/rivals_provider.dart';
import '../../streaks/providers/streak_provider.dart';
import '../../steps/step_sync_service.dart';
import '../../../shared/models/community_post.dart';
import '../../../shared/models/challenge.dart';
import '../../../shared/models/league_status.dart';
import '../../../shared/models/rival.dart';
import '../../../core/theme.dart';
import '../widgets/friends_pulse_section.dart';
import '../widgets/home_shortcuts.dart';
import '../widgets/home_coins_banner.dart';
import '../../social/providers/social_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestHealthPermissions();
  }

  Future<void> _requestHealthPermissions() async {
    try {
      await StepSyncService.instance.requestPermissions();
    } catch (_) {}
    if (!mounted) return;
    // Re-fetch health data now that permissions are granted
    ref.invalidate(healthDaySummaryProvider);
    ref.invalidate(heartRateProvider);  // invalidates all family instances
    ref.invalidate(healthMissionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Normalize to midnight — stable FutureProvider.family cache key across rebuilds
    final today = DateTime(now.year, now.month, now.day);
    final profileAsync   = ref.watch(profileSummaryProvider);
    final summaryAsync   = ref.watch(healthDaySummaryProvider(today));
    final heartRateAsync = ref.watch(heartRateProvider(today));
    final streakAsync    = ref.watch(streakStatusProvider);
    final missionsAsync  = ref.watch(healthMissionsProvider);
    final challengesAsync = ref.watch(myChallengesProvider);
    final leagueAsync    = ref.watch(leagueStatusProvider);
    final battlesAsync   = ref.watch(battlesProvider);
    final walletAsync    = ref.watch(walletBalanceProvider);
    final communityAsync = ref.watch(communityFeedProvider);
    final xpLevelAsync = ref.watch(xpLevelProvider);
    final xpLevel = xpLevelAsync.whenOrNull(data: (x) => x);

    final name = profileAsync.whenOrNull(
      data: (p) { final n = p['name'] as String? ?? ''; return n.isNotEmpty ? n.trim().split(' ').first : 'You'; },
    ) ?? 'You';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'Y';
    final profileAvatarUrl = profileAsync.whenOrNull(
      data: (p) => p['avatar_url'] as String?,
    );

    final summary = summaryAsync.whenOrNull(data: (s) => s);
    final steps = summary?.steps ?? 0;
    final distKm = summary?.distanceKm ?? 0.0;
    final kcal = summary?.calories ?? 0;
    final activeMins = summary?.activeMins ?? 0;
    final bpm = heartRateAsync.whenOrNull(data: (h) => h) ?? 0;
    final streakDays = streakAsync.whenOrNull(data: (s) => s.streakDays) ?? 0;

    final activeChallenges = challengesAsync.whenOrNull(
      data: (list) => list.where((c) => c.isLive).toList(),
    ) ?? [];

    final league = leagueAsync.whenOrNull(data: (l) => l);

    final activeBattle = battlesAsync.whenOrNull(
      data: (list) => list.where((b) => b.status == 'active').isNotEmpty
          ? list.firstWhere((b) => b.status == 'active')
          : null,
    );

    final coins = walletAsync.whenOrNull(
      data: (w) => (w['coin_balance'] as num?)?.toInt() ?? 0,
    ) ?? 0;

    // date string
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${days[now.weekday-1]} · ${months[now.month-1]} ${now.day}';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.voltLime,
          backgroundColor: AppTheme.surface,
          onRefresh: () async {
            ref.invalidate(healthDaySummaryProvider);
            ref.invalidate(heartRateProvider);
            ref.invalidate(healthMissionsProvider);
            ref.invalidate(myChallengesProvider);
            ref.invalidate(leagueStatusProvider);
            ref.invalidate(battlesProvider);
            ref.invalidate(socialActivityFeedProvider);
            ref.invalidate(friendsLeagueStandingsProvider);
            ref.invalidate(walletBalanceProvider);
            ref.invalidate(communityFeedProvider);
            ref.invalidate(streakStatusProvider);
            ref.invalidate(xpLevelProvider);
            ref.invalidate(profileSummaryProvider);
            // Wait briefly for at least the health summary to start fetching
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [

            // ── Header ────────────────────────────────────────────────
            Row(children: [
              // Avatar — photo if available, initial letter fallback
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Builder(builder: (_) {
                  final avatarUrl = ref.watch(avatarUploadProvider).url ?? profileAvatarUrl;
                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.amber.withValues(alpha: 0.9),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(initial,
                            style: GoogleFonts.bigShouldersDisplay(
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: AppTheme.bg))
                        : null,
                  );
                }),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dateStr, style: AppTheme.label(11, color: AppTheme.ink2)),
                Text('Hey, $name',
                  style: GoogleFonts.bigShouldersDisplay(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              ]),
              const Spacer(),
              // Coins
              GestureDetector(
                onTap: () => context.push('/coins'),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.monetization_on_rounded, color: AppTheme.amber, size: 20),
                  const SizedBox(width: 4),
                  Text('$coins',
                    style: GoogleFonts.bigShouldersDisplay(
                      fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.amber)),
                ]),
              ),
              const SizedBox(width: 14),
              // Bell
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(children: [
                  const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), shape: BoxShape.circle),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => context.push('/activities'),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 24),
              ),
            ]),
            const SizedBox(height: 16),

            // ── XP Hero Card ──────────────────────────────────────────
            if (league != null)
              _XpHeroCard(
                league: league,
                streakDays: streakDays,
                steps: steps,
                distKm: distKm,
                kcal: kcal,
                activeMins: activeMins,
                bpm: bpm,
                xpLevel: xpLevel,
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.voltLime, strokeWidth: 2),
                ),
              ),
            const SizedBox(height: 24),

            // ── Daily Missions ────────────────────────────────────────
            _SectionRow(
              title: 'Daily Missions',
              badge: missionsAsync.whenOrNull(
                data: (m) => '${m.where((x) => x.completed).length} / ${m.length}',
              ) ?? '– / 5',
              onSeeAll: () => context.push('/missions'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: missionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(
                    color: AppTheme.voltLime, strokeWidth: 2)),
                error: (_, err) => const SizedBox(),
                data: (missions) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: missions.length,
                  itemBuilder: (_, i) => _MissionCard(mission: missions[i]),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Active Challenges ─────────────────────────────────────
            _SectionRow(
              title: 'Active Challenges',
              badge: activeChallenges.isNotEmpty
                  ? '${activeChallenges.length} LIVE' : null,
              badgeColor: const Color(0xFFEF4444),
              onSeeAll: () => context.push('/challenges'),
            ),
            const SizedBox(height: 12),
            challengesAsync.when(
              loading: () => const SizedBox(height: 140,
                  child: Center(child: CircularProgressIndicator(
                      color: AppTheme.voltLime, strokeWidth: 2))),
              error: (_, err) => const SizedBox(),
              data: (challenges) {
                final live = challenges.where((c) => c.isLive).toList();
                if (live.isEmpty) {
                  return _EmptyCard(
                    message: 'No active challenges',
                    action: 'Browse challenges →',
                    onTap: () => context.push('/challenges'),
                  );
                }
                return _ChallengesCarousel(challenges: live);
              },
            ),
            const SizedBox(height: 24),

            // ── Friends Pulse ─────────────────────────────────────────
            const FriendsPulseSection(),
            const SizedBox(height: 24),

            // ── Live Battle ───────────────────────────────────────────
            if (activeBattle != null) ...[
              _SectionRow(
                title: 'Live Battle',
                badge: _battleTimer(activeBattle),
                onSeeAll: () => context.push('/rivals'),
              ),
              const SizedBox(height: 12),
              _BattleCard(battle: activeBattle, userName: name),
              const SizedBox(height: 24),
            ],

            // ── Shortcuts ─────────────────────────────────────────────
            Text('Shortcuts', style: GoogleFonts.bigShouldersDisplay(
              fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            const HomeShortcuts(),
            const SizedBox(height: 16),

            // ── Coins Banner ──────────────────────────────────────────
            const HomeCoinsBanner(),
            const SizedBox(height: 24),

            // ── Community ─────────────────────────────────────────────
            Row(children: [
              Expanded(child: _SectionRow(
                title: 'Community',
                onSeeAll: () => context.push('/community'),
              )),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  await context.push('/community/create');
                  ref.invalidate(communityFeedProvider);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_rounded, size: 14, color: Color(0xFF050510)),
                    const SizedBox(width: 4),
                    Text('Post',
                        style: AppTheme.label(12, color: AppTheme.bg)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            communityAsync.when(
              loading: () => const SizedBox(height: 60,
                  child: Center(child: CircularProgressIndicator(
                      color: AppTheme.voltLime, strokeWidth: 2))),
              error: (_, err) => const SizedBox(),
              data: (allPosts) {
                if (allPosts.isEmpty) return const SizedBox();
                // Stories row (unique authors)
                final authors = <String, CommunityPost>{};
                for (final p in allPosts) {
                  if (!authors.containsKey(p.userId)) authors[p.userId] = p;
                }
                return Column(children: [
                  // Stories
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _StoryBubble(label: 'You', initial: name[0], isYou: true),
                        ...authors.values.take(5).map((p) =>
                          _StoryBubble(
                            label: p.userName.split(' ').first,
                            initial: p.userName.isNotEmpty ? p.userName[0].toUpperCase() : '?',
                            isYou: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Feed posts
                  ...allPosts.take(3).map((p) => _CommunityPostCard(post: p)),
                ]);
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _battleTimer(Battle battle) {
    if (battle.endTime == null) return '${battle.durationDays}D';
    final remaining = battle.endTime!.difference(DateTime.now());
    if (remaining.isNegative) return 'DONE';
    final d = remaining.inDays;
    final h = remaining.inHours.remainder(24);
    return d > 0 ? '${d}D ${h}H' : '${h}H';
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

String _fmtNum(int n) {
  if (n >= 1000) {
    final s = n.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
  return n.toString();
}

// ── Shared section header ────────────────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  final String title;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onSeeAll;
  const _SectionRow({
    required this.title,
    this.badge,
    this.badgeColor,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title, style: GoogleFonts.bigShouldersDisplay(
          fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppTheme.voltLime).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badge!,
              style: GoogleFonts.bigShouldersDisplay(
                fontSize: 11, fontWeight: FontWeight.w900,
                color: badgeColor ?? AppTheme.voltLime)),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(children: [
            Text('See all', style: AppTheme.label(12, color: AppTheme.ink2)),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_forward_rounded, color: AppTheme.ink2, size: 14),
          ]),
        ),
      ]);
}

// ── XP Hero Card ─────────────────────────────────────────────────────────────

class _XpHeroCard extends StatefulWidget {
  final LeagueStatus league;
  final int streakDays, steps, kcal, activeMins, bpm;
  final double distKm;
  final XpLevel? xpLevel;

  const _XpHeroCard({
    required this.league,
    required this.streakDays,
    required this.steps,
    required this.distKm,
    required this.kcal,
    required this.activeMins,
    required this.bpm,
    this.xpLevel,
  });

  @override
  State<_XpHeroCard> createState() => _XpHeroCardState();
}

class _XpHeroCardState extends State<_XpHeroCard> {
  bool _tooltipVisible = false;
  Timer? _tooltipTimer;

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _onBarTap() {
    setState(() => _tooltipVisible = true);
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tooltipVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.league;
    final currentIdx = l.tierLadder.indexWhere((t) => t.isCurrent);
    final nextTier = (currentIdx >= 0 && currentIdx < l.tierLadder.length - 1)
        ? l.tierLadder[currentIdx + 1]
        : null;
    final xpToNext = l.xpForNext - l.xp;
    final tierColor = _hexColor(l.colorHex);
    final progress = l.xpProgress.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Two panels ───────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // LEFT — XP
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Eyebrow(dotColor: AppTheme.voltLime,
                            label: 'SEASON ${l.season} XP'),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_fmtNum(l.xp),
                              style: GoogleFonts.bigShouldersDisplay(
                                fontSize: 52, fontWeight: FontWeight.w900,
                                color: AppTheme.voltLime,
                                letterSpacing: -1.5, height: 0.85,
                              )),
                            const SizedBox(width: 6),
                            Text('XP',
                              style: GoogleFonts.bigShouldersDisplay(
                                fontSize: 18, fontWeight: FontWeight.w900,
                                color: AppTheme.voltLime.withValues(alpha: 0.45),
                              )),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.voltLime.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: AppTheme.voltLime.withValues(alpha: 0.22)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('🔥',
                              style: TextStyle(fontSize: 13, height: 1)),
                            const SizedBox(width: 6),
                            Text('${widget.streakDays} Day Streak',
                              style: GoogleFonts.bigShouldersDisplay(
                                fontSize: 11, fontWeight: FontWeight.w900,
                                color: AppTheme.voltLime,
                              )),
                          ]),
                        ),
                        if (widget.xpLevel != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'LV ${widget.xpLevel!.level} · ${widget.xpLevel!.title.toUpperCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              letterSpacing: 0.8, color: AppTheme.ink2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Glowing divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.voltLime.withValues(alpha: 0.22),
                        AppTheme.voltLime.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.18, 0.82, 1.0],
                    ),
                  ),
                ),

                // RIGHT — Tier
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Eyebrow(dotColor: tierColor, label: 'CURRENT TIER'),
                        const SizedBox(height: 10),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              const Color(0xFFFFE082),
                              tierColor,
                              const Color(0xFFCC7700),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(l.label.toUpperCase(),
                            style: GoogleFonts.bigShouldersDisplay(
                              fontSize: 34, fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white, height: 0.9,
                            )),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: tierColor.withValues(alpha: 0.28)),
                          ),
                          child: Text('SEASON ${l.season}',
                            style: GoogleFonts.inter(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: tierColor, letterSpacing: 0.5,
                            )),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text('#${l.rankInTier}',
                            style: GoogleFonts.bigShouldersDisplay(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: Colors.white,
                            )),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar + milestones ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Bar with tap-to-reveal tooltip
                GestureDetector(
                  onTap: _onBarTap,
                  behavior: HitTestBehavior.opaque,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final trackW = constraints.maxWidth;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Track background
                          Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          // Animated gradient fill
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 1400),
                            curve: Curves.easeOutBack,
                            builder: (context2, fillValue, child) {
                              final value = fillValue;
                              final fillW = (trackW * value).clamp(0.0, trackW);
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: Container(
                                      height: 7, width: fillW,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          AppTheme.amber,
                                          AppTheme.voltLime,
                                        ]),
                                      ),
                                    ),
                                  ),
                                  // Glowing head dot
                                  if (fillW > 6)
                                    Positioned(
                                      left: fillW - 5.5, top: -2,
                                      child: Container(
                                        width: 11, height: 11,
                                        decoration: BoxDecoration(
                                          color: AppTheme.voltLime,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.voltLime
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 8, spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          // Tooltip — floats above bar head, anchored near fill end
                          if (nextTier != null)
                            Positioned(
                              bottom: 13,
                              right: 0,
                              child: AnimatedOpacity(
                                opacity: _tooltipVisible ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.voltLime
                                          .withValues(alpha: 0.22)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.voltLime
                                            .withValues(alpha: 0.12),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${_fmtNum(xpToNext)} XP',
                                        style: GoogleFonts.bigShouldersDisplay(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.voltLime,
                                        )),
                                      const SizedBox(width: 5),
                                      Text('to reach ',
                                        style: AppTheme.label(10)),
                                      Text(nextTier.label.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF94A3B8),
                                        )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Milestone ticks from tier ladder
                if (l.tierLadder.isNotEmpty)
                  Row(
                    children: List.generate(l.tierLadder.length, (i) {
                      final tier = l.tierLadder[i];
                      final isReached = currentIdx >= 0 && i < currentIdx;
                      final isCurr = tier.isCurrent;
                      final isNext = i == currentIdx + 1;
                      final tickColor = isCurr
                          ? AppTheme.amber
                          : isReached
                              ? AppTheme.voltLime
                              : AppTheme.ink3;
                      final labelColor = isCurr
                          ? AppTheme.amber
                          : isReached
                              ? AppTheme.voltLime.withValues(alpha: 0.6)
                              : isNext
                                  ? const Color(0xFF94A3B8)
                                  : AppTheme.ink3;
                      final abbrev = tier.label.length > 4
                          ? tier.label.substring(0, 4).toUpperCase()
                          : tier.label.toUpperCase();

                      return Expanded(
                        child: Column(children: [
                          Container(
                            width: 1.5, height: 6,
                            decoration: BoxDecoration(
                              color: tickColor,
                              borderRadius: BorderRadius.circular(1),
                              boxShadow: isCurr
                                  ? [BoxShadow(
                                      color: AppTheme.amber.withValues(alpha: 0.6),
                                      blurRadius: 6)]
                                  : isReached
                                      ? [BoxShadow(
                                          color: AppTheme.voltLime
                                              .withValues(alpha: 0.5),
                                          blurRadius: 4)]
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(abbrev,
                            style: GoogleFonts.inter(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              letterSpacing: 0.4, color: labelColor,
                            )),
                        ]),
                      );
                    }),
                  ),
              ],
            ),
          ),

          // ── Colour-coded stat tiles ───────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(children: [
              _HeroStatTile(emoji: '👟', value: _fmtNum(widget.steps),
                label: 'STEPS', valueColor: AppTheme.voltLime,
                bgColor: AppTheme.voltLime.withValues(alpha: 0.07)),
              const SizedBox(width: 6),
              _HeroStatTile(emoji: '⚡', value: widget.distKm.toStringAsFixed(1),
                label: 'KM', valueColor: const Color(0xFF67E8F9),
                bgColor: const Color(0xFF67E8F9).withValues(alpha: 0.07)),
              const SizedBox(width: 6),
              _HeroStatTile(emoji: '🔥', value: '${widget.kcal}',
                label: 'KCAL', valueColor: const Color(0xFFFB923C),
                bgColor: const Color(0xFFFB923C).withValues(alpha: 0.07)),
              const SizedBox(width: 6),
              _HeroStatTile(emoji: '⏱', value: '${widget.activeMins}',
                label: 'MIN', valueColor: Colors.white,
                bgColor: Colors.white.withValues(alpha: 0.04)),
              const SizedBox(width: 6),
              _HeroStatTile(
                emoji: '❤️',
                value: widget.bpm > 0 ? '${widget.bpm}' : '--',
                label: 'BPM', valueColor: const Color(0xFFF87171),
                bgColor: const Color(0xFFF87171).withValues(alpha: 0.07)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Eyebrow label ────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  final Color dotColor;
  final String label;
  const _Eyebrow({required this.dotColor, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4, height: 4,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label,
        style: GoogleFonts.inter(
          fontSize: 9, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: AppTheme.ink3,
        )),
    ],
  );
}

// ── Hero stat tile ────────────────────────────────────────────────────────────

class _HeroStatTile extends StatelessWidget {
  final String emoji, value, label;
  final Color valueColor, bgColor;
  const _HeroStatTile({
    required this.emoji,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 15, height: 1)),
        const SizedBox(height: 4),
        Text(value,
          style: GoogleFonts.bigShouldersDisplay(
            fontSize: 17, fontWeight: FontWeight.w900,
            color: valueColor, height: 1,
          )),
        const SizedBox(height: 3),
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 7.5, fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: valueColor.withValues(alpha: 0.5),
          )),
      ]),
    ),
  );
}


// ── Mission card (horizontal scroll square) ──────────────────────────────────

class _MissionCard extends StatelessWidget {
  final HealthMission mission;
  const _MissionCard({required this.mission});

  static const _photos = {
    'walk':    'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&w=296&h=320&q=75',
    'gym':     'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=296&h=320&q=75',
    'droplet': 'https://images.unsplash.com/photo-1559827291-72ee739d0d9a?auto=format&fit=crop&w=296&h=320&q=75',
    'yoga':    'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=296&h=320&q=75',
    'moon':    'https://images.unsplash.com/photo-1541480601022-2308c0f02487?auto=format&fit=crop&w=296&h=320&q=75',
  };

  static const _icons = {
    'walk':    Icons.directions_walk_rounded,
    'gym':     Icons.fitness_center_rounded,
    'yoga':    Icons.self_improvement_rounded,
    'droplet': Icons.water_drop_rounded,
    'moon':    Icons.bedtime_rounded,
  };

  static const _labels = {
    'walk':    'Walk',
    'gym':     'Gym',
    'yoga':    'Active',
    'droplet': 'Hydrate',
    'moon':    'Sleep',
  };

  @override
  Widget build(BuildContext context) {
    final done = mission.completed;
    final pct = (mission.progressPct * 100).round();
    final photoUrl = _photos[mission.activity] ?? _photos['walk']!;
    final icon = _icons[mission.activity] ?? Icons.directions_walk_rounded;
    final label = _labels[mission.activity] ?? mission.activity;

    return GestureDetector(
      onTap: () => context.push('/missions'),
      child: Container(
        width: 148,
        height: 160,
        margin: const EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [

              // ── Photo ────────────────────────────────────────────
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: done ? 0.78 : 0.44),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, e, st) => ColoredBox(color: AppTheme.surface),
              ),

              // ── Diagonal gradient: dark bottom-left, open top-right ──
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: const [0.25, 0.9],
                    colors: [
                      Colors.transparent,
                      const Color(0xFF050510).withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              // Bottom-to-top fade for content legibility
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.0, 0.55],
                    colors: [Color(0xFF050510), Colors.transparent],
                  ),
                ),
              ),

              // ── Done: lime border overlay ─────────────────────────
              if (done)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.voltLime.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

              // ── Top-left: "✓ Done" badge (completed only) ─────────
              if (done)
                Positioned(
                  top: 9, left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.voltLime,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('✓  Done',
                      style: GoogleFonts.bigShouldersDisplay(
                        fontSize: 10, fontWeight: FontWeight.w900,
                        color: AppTheme.bg, letterSpacing: 0.3,
                      )),
                  ),
                ),

              // ── Top-right: % floating glass chip (active only) ───
              if (!done)
                Positioned(
                  top: 9, right: 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(7, 4, 7, 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$pct%',
                          style: GoogleFonts.bigShouldersDisplay(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: AppTheme.amber,
                          )),
                      ),
                    ),
                  ),
                ),

              // ── Bottom: icon badge + label + name + bar ───────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: done
                                ? AppTheme.voltLime.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 15,
                              color: done ? AppTheme.voltLime : Colors.white),
                        ),
                        const SizedBox(width: 7),
                        Text(label.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 7, fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Colors.white70,
                          )),
                      ]),
                      const SizedBox(height: 6),
                      Text(mission.title,
                        style: GoogleFonts.bigShouldersDisplay(
                          fontSize: 14, fontWeight: FontWeight.w900,
                          height: 1.15,
                          color: done
                              ? AppTheme.voltLime.withValues(alpha: 0.8)
                              : Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: mission.progressPct,
                          minHeight: 2,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(
                              done ? AppTheme.voltLime : AppTheme.amber),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        done ? 'Complete' : mission.progressLabel,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: done
                              ? AppTheme.voltLime.withValues(alpha: 0.6)
                              : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ── Challenges carousel ──────────────────────────────────────────────────────

class _ChallengesCarousel extends StatefulWidget {
  final List<Challenge> challenges;
  const _ChallengesCarousel({required this.challenges});
  @override
  State<_ChallengesCarousel> createState() => _ChallengesCarouselState();
}

class _ChallengesCarouselState extends State<_ChallengesCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 160,
        child: PageView.builder(
          itemCount: widget.challenges.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) =>
              _ChallengeCard(challenge: widget.challenges[i]),
        ),
      ),
      if (widget.challenges.length > 1) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.challenges.length, (i) => Container(
            width: i == _page ? 16 : 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == _page ? AppTheme.voltLime : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    ]);
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  const _ChallengeCard({required this.challenge});

  static String _imageAsset(String activityType, String challengeId) {
    const images = <String, List<String>>{
      'running': ['assets/challenges/running_1.jpg', 'assets/challenges/running_2.jpg'],
      'gym':     ['assets/challenges/gym_1.jpg',     'assets/challenges/gym_2.jpg'],
      'cycling': ['assets/challenges/cycling_1.jpg', 'assets/challenges/cycling_2.jpg'],
      'outdoor': ['assets/challenges/outdoor_1.jpg'],
      'steps':   ['assets/challenges/steps_1.jpg',   'assets/challenges/steps_2.jpg'],
      'walking': ['assets/challenges/steps_2.jpg',   'assets/challenges/walking_2.jpg'],
    };
    final paths = images[activityType.toLowerCase()] ?? images['steps']!;
    if (paths.length == 1) return paths[0];
    return paths[challengeId.codeUnitAt(challengeId.length - 1) % paths.length];
  }

  @override
  Widget build(BuildContext context) {
    final days = challenge.endTime.difference(challenge.startTime).inDays.clamp(1, 9999);
    final daysPassed = DateTime.now().difference(challenge.startTime).inDays.clamp(0, days);
    final pct = (daysPassed / days).clamp(0.0, 1.0);
    final cfg = challenge.activity;

    return GestureDetector(
      onTap: () => context.push('/challenges/${challenge.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: cfg.colorA.withValues(alpha: 0.2)),
                Image.asset(
                  _imageAsset(challenge.activityType, challenge.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => const SizedBox(),
                ),
                Container(color: Colors.black.withValues(alpha: 0.45)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
                      colors: [Colors.transparent, cfg.colorA.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cfg.colorA.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cfg.label.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 0.4)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.voltLime,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${(pct * 100).round()}% DONE',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900,
                              color: AppTheme.bg, letterSpacing: 0.4)),
                        ),
                      ]),
                      const Spacer(),
                      Text(challenge.title,
                        style: GoogleFonts.bigShouldersDisplay(
                          fontSize: 19, fontWeight: FontWeight.w900,
                          color: Colors.white, fontStyle: FontStyle.italic),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${challenge.participantCount} athletes  ·  ${challenge.goalLabel}',
                        style: GoogleFonts.inter(fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65))),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Day $daysPassed/$days',
                          style: GoogleFonts.inter(fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.6))),
                        const SizedBox(width: 8),
                        Text(challenge.prizePoolCoins,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800,
                            color: AppTheme.amber)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  return AppTheme.voltLime;
}

// ── Battle card ──────────────────────────────────────────────────────────────

class _BattleCard extends StatelessWidget {
  final Battle battle;
  final String userName;
  const _BattleCard({required this.battle, required this.userName});

  @override
  Widget build(BuildContext context) {
    final total = battle.challengerSteps + battle.opponentSteps;
    final mySteps = battle.challengerSteps;
    final oppSteps = battle.opponentSteps;
    final myPct = total > 0 ? mySteps / total : 0.5;
    final leading = mySteps >= oppSteps;
    final diff = (mySteps - oppSteps).abs();

    return GestureDetector(
      onTap: () => context.push('/rivals/battle/${battle.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.voltLime.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.voltLime.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(children: [
          // Players row
          Row(children: [
            // You
            Expanded(child: Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.voltLime.withValues(alpha: 0.2),
                  border: Border.all(
                      color: AppTheme.voltLime.withValues(alpha: 0.6), width: 2),
                ),
                child: Center(child: Text(battle.challengerName[0].toUpperCase(),
                  style: GoogleFonts.bigShouldersDisplay(
                    fontSize: 20, fontWeight: FontWeight.w900,
                    color: AppTheme.voltLime))),
              ),
              const SizedBox(height: 4),
              Text('You', style: AppTheme.label(11, color: AppTheme.ink2)),
              Text(_fmtK(mySteps),
                style: GoogleFonts.bigShouldersDisplay(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: AppTheme.voltLime)),
            ])),
            // VS
            Column(children: [
              const Icon(Icons.compare_arrows_rounded, color: AppTheme.amber, size: 22),
              Text('VS', style: AppTheme.label(9, color: AppTheme.ink2)
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
            ]),
            // Opponent
            Expanded(child: Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: Center(child: Text(battle.opponentName[0].toUpperCase(),
                  style: GoogleFonts.bigShouldersDisplay(
                    fontSize: 20, fontWeight: FontWeight.w900,
                    color: Colors.white))),
              ),
              const SizedBox(height: 4),
              Text(battle.opponentName.split(' ').first,
                style: AppTheme.label(11, color: AppTheme.ink2)),
              Text(_fmtK(oppSteps),
                style: GoogleFonts.bigShouldersDisplay(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: Colors.white)),
            ])),
          ]),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: myPct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            leading
                ? 'You lead by +${_fmtK(diff).replaceAll('K', 'K ')} steps  ·  finish strong'
                : 'Behind by ${_fmtK(diff).replaceAll('K', 'K ')} steps  ·  push harder',
            style: AppTheme.label(11, color: AppTheme.ink2),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  String _fmtK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Community ────────────────────────────────────────────────────────────────

class _StoryBubble extends StatelessWidget {
  final String label, initial;
  final bool isYou;
  const _StoryBubble({required this.label, required this.initial, required this.isYou});

  @override
  Widget build(BuildContext context) => Container(
        width: 68,
        margin: const EdgeInsets.only(right: 10),
        child: Column(children: [
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isYou
                    ? AppTheme.amber.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: isYou
                      ? AppTheme.voltLime
                      : Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(initial,
                  style: GoogleFonts.bigShouldersDisplay(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: isYou ? AppTheme.amber : Colors.white)),
              ),
            ),
            if (isYou)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                    color: AppTheme.voltLime, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, size: 12, color: AppTheme.bg),
                ),
              ),
          ]),
          const SizedBox(height: 5),
          Text(label,
            style: AppTheme.label(10, color: AppTheme.ink2)
              .copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ]),
      );
}

class _CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  const _CommunityPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final league = post.userLeague ?? 'free';
    final leagueLabel = league[0].toUpperCase() + league.substring(1).toUpperCase();
    final timeAgo = _ago(post.createdAt);

    return GestureDetector(
      onTap: () => context.push('/community'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Author row
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Center(
                child: Text(
                  post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
                  style: GoogleFonts.bigShouldersDisplay(
                    fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(post.userName, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _leagueColor(league).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(leagueLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: _leagueColor(league))),
                ),
              ]),
              Text(timeAgo, style: AppTheme.label(10, color: AppTheme.ink2)),
            ]),
            const Spacer(),
            Icon(Icons.bookmark_border_rounded, color: AppTheme.ink3, size: 18),
          ]),
          const SizedBox(height: 10),
          // Content
          Text(post.content,
            style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.88), height: 1.4),
            maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          // Actions
          Row(children: [
            Icon(Icons.favorite_border_rounded, color: AppTheme.ink2, size: 15),
            const SizedBox(width: 4),
            Text('${post.likes}', style: AppTheme.label(11, color: AppTheme.ink2)),
            const SizedBox(width: 14),
            Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.ink2, size: 14),
            const SizedBox(width: 4),
            Text('0', style: AppTheme.label(11, color: AppTheme.ink2)),
            const SizedBox(width: 14),
            Icon(Icons.share_outlined, color: AppTheme.ink2, size: 14),
            const SizedBox(width: 4),
            Text('0', style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
        ]),
      ),
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Color _leagueColor(String league) {
    switch (league.toLowerCase()) {
      case 'gold': return AppTheme.amber;
      case 'platinum': return const Color(0xFF94A3B8);
      case 'diamond': return const Color(0xFF67E8F9);
      case 'silver': return const Color(0xFFCBD5E1);
      default: return AppTheme.ink2;
    }
  }
}

// ── Empty state card ─────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message, action;
  final VoidCallback onTap;
  const _EmptyCard({required this.message, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: [
            Text(message, style: AppTheme.label(13, color: AppTheme.ink2)),
            const SizedBox(height: 6),
            Text(action, style: AppTheme.label(12, color: AppTheme.voltLime)
              .copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
