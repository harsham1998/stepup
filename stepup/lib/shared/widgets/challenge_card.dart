import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../../core/theme.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;
  final bool isJoined;
  final VoidCallback? onJoin;

  const ChallengeCard({
    required this.challenge,
    required this.onTap,
    this.isJoined = false,
    this.onJoin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = challenge.activity;
    final isPaid = challenge.isPaid;
    final isLive = challenge.isLive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isJoined
              ? cfg.colorA.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isJoined
                ? cfg.colorA.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.07),
            width: isJoined ? 1.5 : 1.0,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Row 1: title + reward
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppTheme.amber.withValues(alpha: 0.15)
                      : const Color(0xFF34D399).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPaid ? '+${challenge.prizePoolInr} ¢' : '+FREE',
                  style: TextStyle(
                    color: isPaid ? AppTheme.amber : const Color(0xFF34D399),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 2: activity · goal · paid/free
          Text(
            '${cfg.label}  ·  ${challenge.goalLabel}  ·  ${isPaid ? challenge.entryFeeInr + ' entry' : 'free'}',
            style: TextStyle(
              color: cfg.colorA.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: joined count + status + action button
          Row(children: [
            Text(
              '${challenge.participantCount} Joined',
              style: AppTheme.label(11, color: AppTheme.ink2),
            ),
            const SizedBox(width: 6),
            Container(
              width: 3, height: 3,
              decoration: BoxDecoration(
                color: AppTheme.ink3, shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isLive ? 'live' : 'upcoming',
              style: AppTheme.label(11, color: isLive
                  ? const Color(0xFFEF4444)
                  : AppTheme.ink2),
            ),
            const Spacer(),
            if (isJoined)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cfg.colorA.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cfg.colorA.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '✓ JOINED',
                  style: TextStyle(
                    color: cfg.colorA,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: onJoin ?? onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Text(
                    'JOIN →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}
