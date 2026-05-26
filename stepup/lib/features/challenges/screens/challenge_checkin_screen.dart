import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class ChallengeCheckinScreen extends StatelessWidget {
  final String id;
  const ChallengeCheckinScreen({required this.id, super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data — replace with provider in production
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const checkedDays = 3; // days done so far
    const totalDays = 7;
    const dayIndex = 3; // today's index (0-based)

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
                  Text('Day $checkedDays of $totalDays',
                      style: AppTheme.label(13, color: AppTheme.ink2)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Check in', style: AppTheme.bigNum(28)),
              const SizedBox(height: 4),
              Text('7-Day Gym Consistency · today\'s status',
                  style: AppTheme.label(13, color: AppTheme.ink2)),
              const SizedBox(height: 24),

              // Status circle
              Center(
                child: Column(children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.voltLime.withValues(alpha: 0.08),
                      border: Border.all(color: AppTheme.voltLime, width: 3),
                    ),
                    child: Center(
                      child: Text('✓',
                          style: AppTheme.bigNum(44, color: AppTheme.voltLime)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Done today!', style: AppTheme.bigNum(22)),
                  const SizedBox(height: 4),
                  Text('Gym session · 48 min · logged 2 hrs ago',
                      style: AppTheme.label(12, color: AppTheme.ink2),
                      textAlign: TextAlign.center),
                ]),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 16),

              Text('Your week', style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              const SizedBox(height: 10),

              // Week strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final isDone = i < checkedDays;
                  final isToday = i == dayIndex;

                  Color borderColor;
                  Color bgColor;
                  Color textColor;
                  String label;

                  if (isDone) {
                    borderColor = AppTheme.voltLime;
                    bgColor = AppTheme.voltLime;
                    textColor = AppTheme.bg;
                    label = '✓';
                  } else if (isToday) {
                    borderColor = AppTheme.voltLime;
                    bgColor = AppTheme.voltLime.withValues(alpha: 0.2);
                    textColor = AppTheme.voltLime;
                    label = '●';
                  } else {
                    // future day
                    borderColor = AppTheme.ink3;
                    bgColor = Colors.transparent;
                    textColor = AppTheme.ink3;
                    label = '';
                  }

                  return Column(children: [
                    Text(weekDays[i],
                        style: AppTheme.label(10, color: AppTheme.ink2)),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(label,
                            style: AppTheme.label(13, color: textColor)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]);
                }),
              ),

              const Spacer(),

              // Reward banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Finish in top 50% to earn',
                        style: AppTheme.label(12, color: AppTheme.ink2)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('+200 ¢',
                          style: AppTheme.bigNum(12, color: AppTheme.amber)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/leaderboard'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('View consistency leaderboard →',
                      style: AppTheme.label(13, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
