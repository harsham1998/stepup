import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../friends/providers/friends_provider.dart' show challengeFriendsLeaderboardProvider, friendsListProvider;

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ChallengeDetailScreen({required this.id, super.key});
  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  bool _joining = false;
  bool _joined = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      ref.invalidate(challengeProgressProvider(widget.id));
      ref.invalidate(challengeLeaderboardProvider(widget.id));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _join(Challenge challenge) async {
    setState(() => _joining = true);
    try {
      await ApiClient.instance.post('/challenges/${widget.id}/join', {});
      if (!mounted) return;
      setState(() {
        _joining = false;
        _joined = true;
      });
      ref.invalidate(myChallengesProvider);
      ref.invalidate(challengeProgressProvider(widget.id));
      ref.invalidate(challengeLeaderboardProvider(widget.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      final msg = e.toString().toLowerCase();
      if (msg.contains('already') || msg.contains('409')) {
        setState(() => _joined = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg.contains('balance')
                  ? 'Insufficient coins to join'
                  : msg.contains('full')
                      ? 'This challenge is full'
                      : 'Error joining: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeDetailProvider(widget.id));
    final myAsync = ref.watch(myChallengesProvider);
    final alreadyJoined =
        myAsync.whenOrNull(data: (list) => list.any((c) => c.id == widget.id)) ?? false;
    if (alreadyJoined && !_joined) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _joined = true);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: challengeAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) =>
              Center(child: Text('$e', style: AppTheme.label(13))),
          data: (challenge) => _joined
              ? _AfterState(challenge: challenge, challengeId: widget.id)
              : _BeforeState(
                  challenge: challenge,
                  joining: _joining,
                  onJoin: () => _join(challenge),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────── BEFORE STATE ────────────────────────────────

class _BeforeState extends StatelessWidget {
  final Challenge challenge;
  final bool joining;
  final VoidCallback onJoin;

  const _BeforeState({
    required this.challenge,
    required this.joining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = challenge.activity;
    final dateRange = '${_fmt(challenge.startTime)} – ${_fmt(challenge.endTime)}';

    return Column(children: [
      _TopBar(rightWidget: Text('Share', style: AppTheme.label(13, color: AppTheme.ink2))),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _HeroCard(challenge: challenge, cfg: cfg, dateRange: dateRange),
            const SizedBox(height: 12),

            // Mode badge
            Row(children: [
              _Pill(label: challenge.modeLabel, color: AppTheme.ink2, bg: AppTheme.surface),
            ]),
            const SizedBox(height: 14),

            // Daily Missions
            if (challenge.missions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily Missions',
                      style: AppTheme.label(11, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.voltLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.3)),
                    ),
                    child: Text('Earn bonus XP',
                        style: AppTheme.label(9, color: AppTheme.voltLime)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...challenge.missions.map((m) => _MissionPreviewCard(mission: m)),
              const SizedBox(height: 14),
            ],

            // Prize distribution
            if (challenge.prizeTiers.isNotEmpty) ...[
              Text('Prize breakdown',
                  style: AppTheme.label(11, color: AppTheme.ink2)
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              ...challenge.prizeTiers.map((t) => _PrizeTierRow(
                    tier: t,
                    maxCoins: challenge.prizeTiers
                        .map((x) => x.coins)
                        .reduce((a, b) => a > b ? a : b),
                  )),
              const SizedBox(height: 14),
            ],

            // Paid banner
            if (challenge.isPaid) ...[
              _PaidBanner(challenge: challenge),
              const SizedBox(height: 10),
            ],

            // Participant count
            Row(children: [
              const Text('👥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '${challenge.participantCount} participants',
                style: AppTheme.label(12, color: AppTheme.ink2),
              ),
            ]),
          ]),
        ),
      ),

      // Join CTA
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: GestureDetector(
          onTap: joining ? null : onJoin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: challenge.isPaid ? AppTheme.amber : AppTheme.voltLime,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: joining
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bg),
                    )
                  : Text(
                      challenge.isPaid
                          ? '🔓 Unlock Now — ${challenge.entryFeeCoins}'
                          : 'Join Challenge →',
                      style: AppTheme.label(15, color: AppTheme.bg)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    ]);
  }

  static String _fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// ─────────────────────────── AFTER STATE ─────────────────────────────────

class _AfterState extends ConsumerWidget {
  final Challenge challenge;
  final String challengeId;

  const _AfterState({required this.challenge, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(challengeProgressProvider(challengeId));

    return Column(children: [
      _TopBar(
        rightWidget: Row(children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text('Live sync', style: AppTheme.label(10, color: AppTheme.green)),
        ]),
      ),
      Expanded(
        child: progressAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(child: Text('$e', style: AppTheme.label(13))),
          data: (progress) {
            if (progress == null || !progress.joined) {
              return const Center(
                  child: Text('Not joined yet',
                      style: TextStyle(color: AppTheme.ink2)));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Title + day count
                Text(challenge.title, style: AppTheme.bigNum(20)),
                Text(
                  'Day ${progress.daysPassed} of ${progress.totalDays} · ${progress.daysLeft} day${progress.daysLeft == 1 ? '' : 's'} left',
                  style: AppTheme.label(12, color: AppTheme.ink2),
                ),
                const SizedBox(height: 16),

                _StepsHero(progress: progress),
                const SizedBox(height: 12),

                _StatsRow(progress: progress, challenge: challenge),
                const SizedBox(height: 12),

                if (challenge.prizeTiers.isNotEmpty)
                  _PrizeThresholdBar(progress: progress, tiers: challenge.prizeTiers),
                const SizedBox(height: 12),

                if (progress.missionProgress.isNotEmpty) ...[
                  Text('Daily Missions',
                      style: AppTheme.label(11, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...progress.missionProgress.map((mp) => _MissionProgressCard(mp: mp)),
                  const SizedBox(height: 12),
                ],

                _LeaderboardSection(challengeId: challengeId),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () => context.push('/leaderboard'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Center(
                      child: Text('View full leaderboard →',
                          style: AppTheme.label(12, color: AppTheme.ink2)),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ─────────────────────────── SHARED WIDGETS ──────────────────────────────

class _TopBar extends StatelessWidget {
  final Widget rightWidget;
  const _TopBar({required this.rightWidget});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
            rightWidget,
          ],
        ),
      );
}

class _HeroCard extends StatelessWidget {
  final Challenge challenge;
  final ActivityConfig cfg;
  final String dateRange;

  const _HeroCard({
    required this.challenge,
    required this.cfg,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cfg.colorA.withValues(alpha: 0.28),
            cfg.colorB.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: cfg.colorA.withValues(alpha: 0.25)),
      ),
      child: Stack(children: [
        Positioned(
          right: 12,
          bottom: 4,
          child: Text(cfg.emoji,
              style: TextStyle(
                  fontSize: 80, color: Colors.white.withValues(alpha: 0.08))),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Pill(
                  label: challenge.type.toUpperCase(),
                  color: AppTheme.bg,
                  bg: AppTheme.voltLime),
            ]),
            const SizedBox(height: 10),
            Text(challenge.title,
                style: AppTheme.bigNum(22).copyWith(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(dateRange, style: AppTheme.label(11, color: AppTheme.ink2)),
            const SizedBox(height: 12),
            Row(children: [
              _MiniStatBox(label: 'GOAL', value: challenge.goalLabel),
              const SizedBox(width: 6),
              _MiniStatBox(
                  label: 'PRIZE',
                  value: challenge.prizePoolCoins,
                  accent: AppTheme.amber),
              const SizedBox(width: 6),
              _MiniStatBox(label: 'DURATION', value: challenge.durationLabel),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _MiniStatBox extends StatelessWidget {
  final String label, value;
  final Color? accent;
  const _MiniStatBox({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: accent != null
                ? accent!.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: accent != null
                    ? accent!.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(children: [
            Text(label,
                style:
                    AppTheme.label(8, color: AppTheme.ink2).copyWith(letterSpacing: 0.4)),
            const SizedBox(height: 2),
            Text(value,
                style: AppTheme.bigNum(13, color: accent ?? Colors.white)
                    .copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: AppTheme.label(9, color: color)
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.4)),
      );
}

class _MissionPreviewCard extends StatelessWidget {
  final ChallengeMission mission;
  const _MissionPreviewCard({required this.mission});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mission.title,
                  style: AppTheme.label(12, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${mission.target} ${mission.unit}',
                  style: AppTheme.label(10, color: AppTheme.ink2)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.4)),
              ),
              child: Text('+${mission.totalXp} XP',
                  style: AppTheme.label(10, color: AppTheme.voltLime)
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
            if (mission.bonusXp > 0) ...[
              const SizedBox(height: 3),
              Text('+${mission.bonusXp} bonus',
                  style: AppTheme.label(8,
                      color: AppTheme.voltLime.withValues(alpha: 0.7))),
            ],
          ]),
        ]),
      );
}

class _PrizeTierRow extends StatelessWidget {
  final PrizeTier tier;
  final int maxCoins;
  const _PrizeTierRow({required this.tier, required this.maxCoins});

  @override
  Widget build(BuildContext context) {
    final frac = maxCoins == 0 ? 0.0 : (tier.coins / maxCoins).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
          width: 52,
          child: Text(tier.label,
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('+${tier.coins}¢',
            style: AppTheme.label(10, color: AppTheme.voltLime)
                .copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _PaidBanner extends StatelessWidget {
  final Challenge challenge;
  const _PaidBanner({required this.challenge});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.amber.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.amber.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.lock_rounded, color: AppTheme.amber, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Paid challenge',
                  style: AppTheme.label(12, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                'Entry: ${challenge.entryFeeCoins} · Prize pool: ${challenge.prizePoolCoins}',
                style: AppTheme.label(11, color: AppTheme.ink2),
              ),
            ]),
          ),
        ]),
      );
}

class _StepsHero extends StatelessWidget {
  final ChallengeProgress progress;
  const _StepsHero({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress.percent * 100).round();
    final remaining = (progress.goal - progress.current).clamp(0, progress.goal);
    final unit = ['gym', 'cycling', 'outdoor'].contains(progress.activityType)
        ? 'sessions'
        : 'steps';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmtNum(progress.current), style: AppTheme.bigNum(36, color: Colors.white)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(unit, style: AppTheme.label(12, color: AppTheme.ink2)),
            ),
            const Spacer(),
            Text('$pct%', style: AppTheme.bigNum(22, color: AppTheme.voltLime)),
          ],
        ),
        const SizedBox(height: 4),
        Text('today · ${_fmtNum(progress.goal)} goal',
            style: AppTheme.label(11, color: AppTheme.ink2)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.percent.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
          ),
        ),
        const SizedBox(height: 6),
        Text('$remaining more $unit to hit goal',
            style: AppTheme.label(10, color: AppTheme.ink2)),
      ]),
    );
  }

  static String _fmtNum(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k' : '$n';
}

class _StatsRow extends StatelessWidget {
  final ChallengeProgress progress;
  final Challenge challenge;
  const _StatsRow({required this.progress, required this.challenge});

  @override
  Widget build(BuildContext context) => Row(children: [
        _StatBox(
          label: 'RANK',
          value: progress.rank != null ? '#${progress.rank}' : '—',
          accent: AppTheme.voltLime,
        ),
        const SizedBox(width: 6),
        _StatBox(label: 'DAYS LEFT', value: '${progress.daysLeft}d'),
        const SizedBox(width: 6),
        _StatBox(
          label: 'STREAK',
          value: '${_streak(progress.dailyCheckins)}🔥',
          accent: AppTheme.voltLime,
        ),
        const SizedBox(width: 6),
        _StatBox(
          label: 'PRIZE',
          value: progress.prizePoolCoins,
          accent: AppTheme.amber,
        ),
      ]);

  static int _streak(List<bool> checkins) {
    var s = 0;
    for (var i = checkins.length - 1; i >= 0; i--) {
      if (!checkins[i]) break;
      s++;
    }
    return s;
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color? accent;
  const _StatBox({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: accent != null ? accent!.withValues(alpha: 0.08) : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: accent != null ? accent!.withValues(alpha: 0.3) : AppTheme.border),
          ),
          child: Column(children: [
            Text(label,
                style:
                    AppTheme.label(8, color: AppTheme.ink2).copyWith(letterSpacing: 0.4)),
            const SizedBox(height: 3),
            Text(value,
                style: AppTheme.bigNum(13, color: accent ?? Colors.white)
                    .copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _PrizeThresholdBar extends StatelessWidget {
  final ChallengeProgress progress;
  final List<PrizeTier> tiers;
  const _PrizeThresholdBar({required this.progress, required this.tiers});

  @override
  Widget build(BuildContext context) {
    final int totalParticipants = progress.totalParticipants;
    final int? rank = progress.rank;
    final qualifyingTier = rank == null || totalParticipants == 0
        ? null
        : tiers
            .where((t) {
              final cutoff = (t.topPercent / 100 * totalParticipants).ceil();
              return rank <= cutoff;
            })
            .fold<PrizeTier?>(
                null,
                (best, t) =>
                    best == null || t.topPercent < best.topPercent ? t : best);

    final pct = progress.percent.clamp(0.0, 1.0);
    final qualified = qualifyingTier != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Prize threshold', style: AppTheme.label(11, color: AppTheme.ink2)),
          Text(
            qualified ? 'Earning ${qualifyingTier.coins}¢ ✓' : 'Not qualifying yet',
            style: AppTheme.label(11, color: qualified ? AppTheme.amber : AppTheme.ink2)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: const AlwaysStoppedAnimation(AppTheme.amber),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            rank != null ? '▲ You: #$rank' : 'Your rank: —',
            style: AppTheme.label(9,
                    color: qualified ? AppTheme.voltLime : AppTheme.ink2)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          Text('Top 50% threshold', style: AppTheme.label(9, color: AppTheme.ink2)),
        ]),
      ]),
    );
  }
}

class _MissionProgressCard extends StatelessWidget {
  final MissionProgress mp;
  const _MissionProgressCard({required this.mp});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: mp.completed
                  ? AppTheme.voltLime.withValues(alpha: 0.4)
                  : AppTheme.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(mp.title,
                  style: AppTheme.label(12, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: mp.completed
                    ? AppTheme.voltLime.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: mp.completed
                        ? AppTheme.voltLime.withValues(alpha: 0.5)
                        : AppTheme.border),
              ),
              child: Text(
                mp.completed ? '+${mp.totalXp} XP ✓' : '+${mp.totalXp} XP',
                style: AppTheme.label(10,
                        color: mp.completed ? AppTheme.voltLime : AppTheme.ink2)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: mp.percent,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor:
                  AlwaysStoppedAnimation(mp.completed ? AppTheme.voltLime : AppTheme.ink2),
            ),
          ),
          const SizedBox(height: 4),
          Text('${mp.current} / ${mp.target} ${mp.unit}',
              style: AppTheme.label(9, color: AppTheme.ink2)),
        ]),
      );
}

class _LiveLeaderboard extends StatelessWidget {
  final ChallengeLeaderboard lb;
  const _LiveLeaderboard({required this.lb});

  @override
  Widget build(BuildContext context) {
    final all = lb.participants;
    final yourRank = lb.yourRank;

    final Set<int> showRanks = {1, 2, 3};
    if (yourRank != null) {
      showRanks.add(yourRank);
      if (yourRank + 1 <= all.length) showRanks.add(yourRank + 1);
    }

    final rows = all.where((e) => showRanks.contains(e.rank)).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Live standings',
            style: AppTheme.label(11, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w700)),
        Text('${lb.total} players', style: AppTheme.label(10, color: AppTheme.ink2)),
      ]),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: rows
              .map((e) => _LbRow(entry: e, isYou: e.rank == yourRank))
              .toList(),
        ),
      ),
    ]);
  }
}

class _LbRow extends StatelessWidget {
  final ChallengeParticipant entry;
  final bool isYou;
  const _LbRow({required this.entry, required this.isYou});

  @override
  Widget build(BuildContext context) {
    final rankEmoji = entry.rank == 1
        ? '🏆'
        : entry.rank == 2
            ? '🥈'
            : entry.rank == 3
                ? '🥉'
                : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isYou ? AppTheme.voltLime.withValues(alpha: 0.06) : null,
        border: Border(
          top: BorderSide(
            color: isYou
                ? AppTheme.voltLime.withValues(alpha: 0.15)
                : AppTheme.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: rankEmoji != null
              ? Text(rankEmoji, style: const TextStyle(fontSize: 14))
              : Text('#${entry.rank}',
                  style: AppTheme.label(11, color: AppTheme.ink2)
                      .copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isYou ? 'You' : entry.displayName,
            style: AppTheme.label(12,
                    color: isYou ? AppTheme.voltLime : Colors.white)
                .copyWith(fontWeight: isYou ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
        if (entry.xpEarned > 0) ...[
          Text('+${entry.xpEarned}XP',
              style: AppTheme.label(9, color: AppTheme.voltLime)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
        ],
        Text(
          entry.current >= 1000
              ? '${(entry.current / 1000).toStringAsFixed(1)}k'
              : '${entry.current}',
          style: AppTheme.label(12,
                  color: isYou ? AppTheme.voltLime : AppTheme.ink2)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}

class _LeaderboardSection extends ConsumerStatefulWidget {
  final String challengeId;
  const _LeaderboardSection({required this.challengeId});

  @override
  ConsumerState<_LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends ConsumerState<_LeaderboardSection> {
  bool _friendsFilter = false;

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final hasFriends = friendsAsync.whenOrNull(data: (list) => list.isNotEmpty) ?? false;

    final leaderboardAsync = _friendsFilter
        ? ref.watch(challengeFriendsLeaderboardProvider(widget.challengeId))
        : ref.watch(challengeLeaderboardProvider(widget.challengeId));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (hasFriends)
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _friendsFilter = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_friendsFilter ? AppTheme.voltLime : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text('Everyone', style: AppTheme.label(11,
                      color: !_friendsFilter ? Colors.black : AppTheme.ink2)
                      .copyWith(fontWeight: !_friendsFilter ? FontWeight.w700 : FontWeight.normal)),
                ),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _friendsFilter = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _friendsFilter ? AppTheme.voltLime : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text('Friends 👥', style: AppTheme.label(11,
                      color: _friendsFilter ? Colors.black : AppTheme.ink2)
                      .copyWith(fontWeight: _friendsFilter ? FontWeight.w700 : FontWeight.normal)),
                ),
              ),
            )),
          ]),
        ),
      const SizedBox(height: 8),
      leaderboardAsync.when(
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(color: AppTheme.voltLime, strokeWidth: 1.5)),
        ),
        error: (err, st) => const SizedBox.shrink(),
        data: (lb) {
          if (_friendsFilter && lb.participants.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(children: [
                Text('None of your friends have joined yet',
                    style: AppTheme.label(12, color: AppTheme.ink2)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push('/challenges/${widget.challengeId}/invite'),
                  child: Text('Invite Friends →',
                      style: AppTheme.label(12, color: AppTheme.voltLime)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            );
          }
          return _LiveLeaderboard(lb: lb);
        },
      ),
    ]);
  }
}
