import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ChallengeDetailScreen({required this.id, super.key});
  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState
    extends ConsumerState<ChallengeDetailScreen> {
  bool _joining = false;
  bool _joined = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await ApiClient.instance.post('/challenges/${widget.id}/join', {});
      if (mounted) {
        setState(() {
          _joining = false;
          _joined = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined! Good luck 🏆')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      final msg = e.toString().toLowerCase();
      if (msg.contains('already') || msg.contains('409')) {
        setState(() => _joined = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're already in this challenge!")),
        );
      } else if (msg.contains('balance')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient coins to join')),
        );
      } else if (msg.contains('full')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This challenge is full')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeDetailProvider(widget.id));
    final myAsync = ref.watch(myChallengesProvider);
    final alreadyJoined = myAsync.whenOrNull(
            data: (list) => list.any((c) => c.id == widget.id)) ??
        false;
    if (alreadyJoined && !_joined) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _joined = true);
      });
    }
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: challengeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text('$e', style: AppTheme.label(13))),
          data: (c) => _DetailBody(
            challenge: c,
            joining: _joining,
            joined: _joined,
            onJoin: _join,
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Challenge challenge;
  final bool joining, joined;
  final VoidCallback onJoin;
  const _DetailBody({
    required this.challenge,
    required this.joining,
    required this.joined,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = challenge.activity;
    final days =
        challenge.endTime.difference(challenge.startTime).inDays + 1;
    final dateRange =
        '${_fmt(challenge.startTime)} – ${_fmt(challenge.endTime)}';

    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
            Text('Share', style: AppTheme.label(13, color: AppTheme.ink2)),
          ],
        ),
      ),
      const SizedBox(height: 12),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Cover card
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cfg.colorA.withValues(alpha: 0.3),
                    cfg.colorB.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: cfg.colorA.withValues(alpha: 0.3)),
              ),
              child: Stack(children: [
                Positioned(
                  right: 16,
                  bottom: 8,
                  child: Text(cfg.emoji,
                      style: TextStyle(
                          fontSize: 80,
                          color: Colors.white.withValues(alpha: 0.1))),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.voltLime,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          challenge.type.toUpperCase(),
                          style: AppTheme.label(10, color: AppTheme.bg)
                              .copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5),
                        ),
                      ),
                      const Spacer(),
                      // Title
                      Text(challenge.title,
                          style: AppTheme.bigNum(22)
                              .copyWith(fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(dateRange,
                          style: AppTheme.label(11, color: AppTheme.ink2)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // Stats row — 4 boxes
            Row(children: [
              _StatBox(label: 'GOAL', value: challenge.goalLabel),
              const SizedBox(width: 8),
              _StatBox(
                label: 'DAILY GOAL',
                value: days > 1
                    ? '${(challenge.stepGoal / days).round()}${_goalUnit(challenge.activityType)}'
                    : challenge.goalLabel,
              ),
              const SizedBox(width: 8),
              _StatBox(
                  label: 'REWARD',
                  value: challenge.prizePoolCoins,
                  accent: AppTheme.amber),
              const SizedBox(width: 8),
              _StatBox(
                  label: 'DURATION', value: challenge.durationLabel),
            ]),
            const SizedBox(height: 14),

            // Daily goals list
            Text('Daily goals',
                style: AppTheme.label(11, color: AppTheme.ink2)
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            ..._dailyGoals(challenge).map((g) => _GoalRow(
                  icon: g.$1,
                  text: g.$2,
                )),

            // Entry fee banner
            if (challenge.isPaid) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.amber.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.lock_rounded,
                      color: AppTheme.amber, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid challenge',
                              style: AppTheme.label(12, color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                              'Entry fee: ${challenge.entryFeeCoins} · Prize pool: ${challenge.prizePoolCoins}',
                              style: AppTheme.label(11,
                                  color: AppTheme.ink2)),
                        ]),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 20),
          ]),
        ),
      ),

      // CTA
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(children: [
          if (joined) ...[
            GestureDetector(
              onTap: () =>
                  context.push('/challenges/${challenge.id}/checkin'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.voltLime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.voltLime.withValues(alpha: 0.5)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.voltLime, size: 18),
                      const SizedBox(width: 8),
                      Text('Check in today →',
                          style: AppTheme.label(14,
                                  color: AppTheme.voltLime)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ]),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Center(
                child: Text('✓ Joined this challenge',
                    style: AppTheme.label(12, color: AppTheme.ink2)),
              ),
            ),
          ] else
            GestureDetector(
              onTap: onJoin,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: challenge.isPaid
                      ? AppTheme.amber
                      : AppTheme.voltLime,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: joining
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: challenge.isPaid
                                  ? AppTheme.bg
                                  : AppTheme.bg),
                        )
                      : Text(
                          challenge.isPaid
                              ? 'Unlock Now  ${challenge.entryFeeCoins}'
                              : 'Join Challenge →',
                          style: AppTheme.label(15, color: AppTheme.bg)
                              .copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ]),
      ),
    ]);
  }

  static String _fmt(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String _goalUnit(String type) {
    switch (type) {
      case 'cycling': return 'km';
      case 'gym': return ' sessions';
      case 'outdoor': return ' matches';
      default: return '/day';
    }
  }

  static List<(String, String)> _dailyGoals(Challenge c) {
    switch (c.activityType) {
      case 'gym':
        return [
          ('💪', 'Complete ${c.goalLabel} this challenge'),
          ('💧', 'Stay hydrated — 2L water'),
          ('🌙', '7+ hrs sleep for recovery'),
        ];
      case 'cycling':
        return [
          ('🚴', 'Ride ${c.goalLabel} total'),
          ('💧', 'Hydrate well during rides'),
          ('🌙', '7+ hrs sleep'),
        ];
      case 'running':
        return [
          ('🏃', '${c.goalLabel} over the challenge'),
          ('💧', '2L water daily'),
          ('🌙', '7+ hrs sleep'),
        ];
      default:
        final days =
            c.endTime.difference(c.startTime).inDays.clamp(1, 9999);
        final daily = (c.stepGoal / days).round();
        return [
          ('👟', '~$daily steps per day'),
          ('💧', '2L water daily'),
          ('🌙', '7+ hrs sleep'),
        ];
    }
  }
}

class _GoalRow extends StatelessWidget {
  final String icon, text;
  const _GoalRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(text,
              style: AppTheme.label(13, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w500)),
        ]),
      );
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
            color: accent != null
                ? accent!.withValues(alpha: 0.08)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accent != null
                  ? accent!.withValues(alpha: 0.3)
                  : AppTheme.border,
            ),
          ),
          child: Column(children: [
            Text(label,
                style: AppTheme.label(9, color: AppTheme.ink2)
                    .copyWith(letterSpacing: 0.4)),
            const SizedBox(height: 3),
            Text(value,
                style: AppTheme.bigNum(13,
                        color: accent ?? Colors.white)
                    .copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}
