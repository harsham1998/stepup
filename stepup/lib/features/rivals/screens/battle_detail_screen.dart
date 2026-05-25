import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class BattleDetailScreen extends StatelessWidget {
  final String battleId;
  const BattleDetailScreen({required this.battleId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.voltLime.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('WEEK 21 · LIVE',
                        style: AppTheme.label(11, color: AppTheme.voltLime)
                            .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('WEEKLY BATTLE',
                  style: AppTheme.bigNum(24, color: AppTheme.voltLime)),
              const SizedBox(height: 16),

              // Versus card
              Row(
                children: [
                  Expanded(
                    child: Column(children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            AppTheme.voltLime.withValues(alpha: 0.3),
                            Colors.transparent,
                          ]),
                          border: Border.all(
                              color: AppTheme.voltLime, width: 2),
                        ),
                        child: Center(
                          child: Text('R',
                              style: AppTheme.bigNum(28,
                                  color: AppTheme.voltLime)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('You',
                          style: AppTheme.label(14, color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text('Gold III',
                          style: AppTheme.label(11, color: AppTheme.ink2)),
                      const SizedBox(height: 6),
                      Text('4,240',
                          style: AppTheme.bigNum(36, color: AppTheme.voltLime)),
                    ]),
                  ),
                  Column(children: [
                    const Icon(Icons.sports_mma_rounded,
                        color: Color(0xFFEF4444), size: 28),
                    const SizedBox(height: 4),
                    Text('VS',
                        style: AppTheme.bigNum(14, color: AppTheme.ink3)),
                  ]),
                  Expanded(
                    child: Column(children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 2),
                        ),
                        child: Center(
                          child: Text('A', style: AppTheme.bigNum(28)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Aarav',
                          style: AppTheme.label(14, color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text('Gold III',
                          style: AppTheme.label(11, color: AppTheme.ink2)),
                      const SizedBox(height: 6),
                      Text('3,890', style: AppTheme.bigNum(36)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.52,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.voltLime),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('52%',
                      style: AppTheme.label(11, color: AppTheme.ink2)),
                  Text('2d 14h left',
                      style: AppTheme.label(11, color: AppTheme.ink3)),
                  Text('48%',
                      style: AppTheme.label(11, color: AppTheme.ink2)),
                ],
              ),
              const SizedBox(height: 20),

              Text('BREAKDOWN',
                  style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
                      letterSpacing: 1.2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              ...[
                ['Steps', '32,400', '28,800'],
                ['Gym', '4 sessions', '3 sessions'],
                ['Mindful', '90 min', '40 min'],
                ['Streak', '12d', '9d'],
              ].map((row) => Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(row[0],
                          style: AppTheme.label(13, color: AppTheme.ink2)),
                    ),
                    Text(row[1],
                        style: AppTheme.label(13, color: AppTheme.voltLime)
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text('vs',
                        style: AppTheme.label(11, color: AppTheme.ink3)),
                    Text(row[2],
                        style: AppTheme.label(13, color: Colors.white)),
                  ],
                ),
              )),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: AppTheme.amber, size: 16),
                  const SizedBox(width: 8),
                  Text('Winner takes +150 ¢ and reputation bonus',
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
