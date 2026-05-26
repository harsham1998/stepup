import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class ReputationScreen extends StatelessWidget {
  const ReputationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child:
                        Text('Public', style: AppTheme.label(11, color: AppTheme.ink2)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('FITNESS REPUTATION',
                  style: AppTheme.bigNum(22).copyWith(letterSpacing: 0.5)),
              const SizedBox(height: 20),

              // Score hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.voltLime.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    center: Alignment.topCenter,
                    radius: 1.5,
                  ),
                ),
                child: Column(children: [
                  Text('847',
                      style: AppTheme.bigNum(84, color: AppTheme.voltLime)),
                  const SizedBox(height: 8),
                  Text('TOP 8% NATIONALLY',
                      style: AppTheme.label(11, color: AppTheme.ink2)
                          .copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward_rounded,
                          color: AppTheme.voltLime, size: 14),
                      const SizedBox(width: 4),
                      Text('+42 this month',
                          style: AppTheme.label(12,
                              color: AppTheme.voltLime)),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              Text('BREAKDOWN',
                  style: AppTheme.label(10, color: AppTheme.ink2).copyWith(
                      letterSpacing: 1.2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),

              ...[
                ['Consistency', 92, AppTheme.voltLime],
                ['Challenge wins', 78, AppTheme.voltLime],
                ['Streak depth', 85, AppTheme.amber],
                ['Activity mix', 64, AppTheme.amber],
                ['Social', 51, AppTheme.ink2],
              ].map((row) {
                final label = row[0] as String;
                final val = row[1] as int;
                final color = row[2] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label,
                              style: AppTheme.label(13, color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('$val',
                              style: AppTheme.bigNum(14, color: color)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: val / 100,
                          minHeight: 4,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _StatBox(icon: Icons.local_fire_department_rounded,
                    value: '28D', label: 'Best streak', color: AppTheme.voltLime)),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(icon: Icons.emoji_events_rounded,
                    value: '42', label: 'Challenges done', color: AppTheme.voltLime)),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(icon: Icons.military_tech_rounded,
                    value: '8', label: 'Top 50%', color: AppTheme.voltLime)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatBox({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: AppTheme.bigNum(22)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.label(10, color: AppTheme.ink2)),
      ],
    ),
  );
}
