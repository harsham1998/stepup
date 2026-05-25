import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class ConsistencyCalendarScreen extends StatelessWidget {
  const ConsistencyCalendarScreen({super.key});

  // Simulated intensity values (0-3); replace with real data from API
  static const _intensities = [
    0, 1, 2, 3, 1, 2, 3, 2, 1, 0,
    2, 3, 3, 2, 1, 2, 3, 3, 2, 1,
    2, 1, 3, 2, 3, 3, 2, 0, 0, 0,
  ];

  Color _cellColor(int intensity) {
    switch (intensity) {
      case 0: return Colors.white.withValues(alpha: 0.06);
      case 1: return AppTheme.voltLime.withValues(alpha: 0.25);
      case 2: return AppTheme.voltLime.withValues(alpha: 0.60);
      default: return AppTheme.voltLime;
    }
  }

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
                  Text('May', style: AppTheme.label(13, color: AppTheme.ink2)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Consistency', style: AppTheme.bigNum(28)),
              const SizedBox(height: 4),
              Text('Your streak across all challenges',
                  style: AppTheme.label(13, color: AppTheme.ink2)),
              const SizedBox(height: 16),

              // Streak summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.voltLime.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.voltLime.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current streak',
                            style: AppTheme.label(11, color: AppTheme.ink3)),
                        const SizedBox(height: 4),
                        Text('12 Days ★',
                            style: AppTheme.bigNum(36, color: AppTheme.voltLime)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Best',
                            style: AppTheme.label(11, color: AppTheme.ink3)),
                        const SizedBox(height: 4),
                        Text('28D', style: AppTheme.bigNum(22)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'This month · 21 / 30 days active',
                style: AppTheme.label(12, color: AppTheme.ink3),
              ),
              const SizedBox(height: 12),

              // Calendar heatmap
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(30, (i) {
                  final intensity = _intensities[i % _intensities.length];
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _cellColor(intensity),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Less', style: AppTheme.label(10, color: AppTheme.ink3)),
                  Row(
                    children: [0, 1, 2, 3].map((i) => Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: _cellColor(i),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )).toList(),
                  ),
                  Text('More', style: AppTheme.label(10, color: AppTheme.ink3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
