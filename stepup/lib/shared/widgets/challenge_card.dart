import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/challenge.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const ChallengeCard({required this.challenge, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${challenge.title}, ${challenge.isPaid ? 'paid' : 'free'} challenge, prize pool ${challenge.prizePoolInr}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF13131F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: challenge.isPaid
                  ? AppTheme.primary.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _TypeBadge(challenge),
                const Spacer(),
                Text(challenge.prizePoolInr,
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              Text(challenge.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${(challenge.stepGoal / 1000).toStringAsFixed(challenge.stepGoal % 1000 == 0 ? 0 : 1)}k steps',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final Challenge c;
  const _TypeBadge(this.c);

  @override
  Widget build(BuildContext context) {
    final color = c.isPaid ? const Color(0xFFFBBF24) : const Color(0xFF34D399);
    final label = c.isPaid ? 'PAID POOL' : 'FREE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}
