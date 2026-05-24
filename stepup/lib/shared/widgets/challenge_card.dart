import 'package:flutter/material.dart';
import '../models/challenge.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const ChallengeCard({required this.challenge, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = challenge.activity;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cfg.colorA.withValues(alpha: 0.25), cfg.colorB.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: cfg.colorA.withValues(alpha: 0.35)),
        ),
        child: Stack(
          children: [
            // Background emoji watermark
            Positioned(
              right: -8,
              top: -8,
              child: Text(cfg.emoji,
                  style: const TextStyle(fontSize: 80, height: 1)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: activity badge + status
                  Row(children: [
                    _ActivityBadge(cfg.emoji, cfg.label, cfg.colorA),
                    const SizedBox(width: 8),
                    if (challenge.isLive)
                      _LiveBadge()
                    else
                      _UpcomingBadge(),
                    const Spacer(),
                    if (challenge.isPaid)
                      _PaidBadge()
                    else
                      _FreeBadge(),
                  ]),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    challenge.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Goal + duration
                  Text(
                    '${challenge.goalLabel}  •  ${challenge.durationLabel}',
                    style: TextStyle(color: cfg.colorA.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(children: [
                    _StatChip(
                      icon: Icons.emoji_events_rounded,
                      label: challenge.prizePoolInr,
                      color: const Color(0xFF34D399),
                    ),
                    const SizedBox(width: 8),
                    if (challenge.isPaid) ...[
                      _StatChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: challenge.entryFeeInr,
                        color: const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _StatChip(
                      icon: Icons.people_rounded,
                      label: '${challenge.participantCount}${challenge.maxParticipants != null ? "/${challenge.maxParticipants}" : ""} joined',
                      color: cfg.colorA,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 4),
      Text(label.toUpperCase(),
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    ]),
  );
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
      const SizedBox(width: 4),
      const Text('LIVE', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _UpcomingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF6B7280).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text('UPCOMING',
        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.w800)),
  );
}

class _PaidBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text('💰 PRIZE',
        style: TextStyle(color: Color(0xFFFBBF24), fontSize: 9, fontWeight: FontWeight.w800)),
  );
}

class _FreeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF34D399).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text('FREE',
        style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w800)),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: color, size: 12),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  ]);
}
