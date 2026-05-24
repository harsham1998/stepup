import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../shared/widgets/neon_button.dart';
import '../../../core/api_client.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ChallengeDetailScreen({required this.id, super.key});
  @override
  ConsumerState<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  bool _joining = false;
  bool _joined = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await ApiClient.instance.post('/challenges/${widget.id}/join', {});
      if (mounted) {
        setState(() { _joining = false; _joined = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined! Good luck 🏆'),
              backgroundColor: Color(0xFF6366F1)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _joining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeDetailProvider(widget.id));
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D17),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: Color(0xFF9CA3AF))),
        ),
        data: (challenge) => _DetailBody(
          challenge: challenge,
          joining: _joining,
          joined: _joined,
          onJoin: _join,
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
    return CustomScrollView(
      slivers: [
        // Hero header
        SliverToBoxAdapter(
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cfg.colorA.withValues(alpha: 0.4), cfg.colorB.withValues(alpha: 0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Watermark emoji
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Text(cfg.emoji,
                      style: const TextStyle(fontSize: 100, height: 1)),
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
                // Text content
                Positioned(
                  left: 16,
                  right: 100,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        _ActivityBadge(cfg.emoji, cfg.label, cfg.colorA),
                        const SizedBox(width: 8),
                        if (challenge.isLive) _LiveDot(),
                      ]),
                      const SizedBox(height: 8),
                      Text(challenge.title,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.w900, height: 1.2)),
                      const SizedBox(height: 4),
                      Text('${challenge.goalLabel}  •  ${challenge.durationLabel}',
                          style: TextStyle(
                              color: cfg.colorA.withValues(alpha: 0.85),
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Prize + entry row
              Row(children: [
                _HeroStat(
                  label: 'PRIZE POOL',
                  value: challenge.prizePoolInr,
                  color: const Color(0xFF34D399),
                  icon: Icons.emoji_events_rounded,
                ),
                const SizedBox(width: 10),
                _HeroStat(
                  label: challenge.isPaid ? 'ENTRY FEE' : 'ENTRY',
                  value: challenge.entryFeeInr,
                  color: challenge.isPaid ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(width: 10),
                _HeroStat(
                  label: 'JOINED',
                  value: '${challenge.participantCount}${challenge.maxParticipants != null ? "/${challenge.maxParticipants}" : ""}',
                  color: cfg.colorA,
                  icon: Icons.people_rounded,
                ),
              ]),
              const SizedBox(height: 16),

              // Dates
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Row(children: [
                  Expanded(child: _DateItem(
                      label: 'STARTS',
                      date: challenge.startTime,
                      icon: Icons.play_circle_outline_rounded)),
                  Container(width: 1, height: 32,
                      color: Colors.white.withValues(alpha: 0.1)),
                  Expanded(child: _DateItem(
                      label: 'ENDS',
                      date: challenge.endTime,
                      icon: Icons.flag_rounded)),
                ]),
              ),
              const SizedBox(height: 16),

              // How it works
              const Text('HOW IT WORKS',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              ..._howItWorks(challenge).asMap().entries.map((e) =>
                  _HowStep(number: e.key + 1, text: e.value)),
              const SizedBox(height: 24),

              // CTA
              NeonButton(
                label: joined ? '✓ You\'re In!' : (challenge.isPaid
                    ? 'Join for ${challenge.entryFeeInr}'
                    : 'Join Free'),
                onPressed: joined ? null : onJoin,
                isLoading: joining,
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ],
    );
  }

  List<String> _howItWorks(Challenge c) {
    final activity = c.activityType;
    if (activity == 'gym') {
      return [
        'Log your gym sessions using the app each day',
        'Reach ${c.goalLabel} over the challenge period',
        'Top performers share the prize pool',
      ];
    } else if (activity == 'outdoor') {
      return [
        'Track your outdoor game sessions in the app',
        'Each verified session counts toward your goal of ${c.goalLabel}',
        'Highest match count wins the prize pool',
      ];
    } else if (activity == 'cycling') {
      return [
        'Track your cycling rides using GPS or manual entry',
        'Accumulate ${c.goalLabel} to complete the challenge',
        'Top performers share the prize pool equally',
      ];
    } else {
      return [
        'Walk or run throughout the day — every step counts',
        'Reach ${c.goalLabel} over the ${c.durationLabel} challenge',
        'Top performers split the ₹${(c.prizePool / 100).toStringAsFixed(0)} prize pool',
      ];
    }
  }
}

class _ActivityBadge extends StatelessWidget {
  final String emoji, label;
  final Color color;
  const _ActivityBadge(this.emoji, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 11)),
      const SizedBox(width: 4),
      Text(label.toUpperCase(),
          style: const TextStyle(color: Colors.white70, fontSize: 9,
              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    ]),
  );
}

class _LiveDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
      const SizedBox(width: 4),
      const Text('LIVE', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9,
          fontWeight: FontWeight.w800)),
    ]),
  );
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _HeroStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 8,
            fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    ),
  );
}

class _DateItem extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  const _DateItem({required this.label, required this.date, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: const Color(0xFF6B7280), size: 14),
    const SizedBox(height: 4),
    Text(label,
        style: const TextStyle(color: Color(0xFF4B5563), fontSize: 8,
            fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    const SizedBox(height: 2),
    Text(_fmt(date),
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
  ]);

  String _fmt(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

class _HowStep extends StatelessWidget {
  final int number;
  final String text;
  const _HowStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text('$number',
              style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, height: 1.4)),
      ),
    ]),
  );
}
