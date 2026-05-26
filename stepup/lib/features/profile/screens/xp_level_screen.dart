import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class XpLevelScreen extends StatelessWidget {
  const XpLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const currentLevel = 23;
    const currentXp = 14200;
    const nextLevelXp = 21000;
    const progress = currentXp / nextLevelXp;

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
                  Text('LV $currentLevel → ${currentLevel + 1}',
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                ],
              ),
              const SizedBox(height: 16),
              Text('LEVEL',
                  style: AppTheme.bigNum(22).copyWith(letterSpacing: 0.5)),
              const SizedBox(height: 16),

              // Current level card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.voltLime.withValues(alpha: 0.10),
                      AppTheme.amber.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppTheme.voltLime, Color(0x33D4FF3A)],
                      ),
                    ),
                    child: Center(
                      child: Text('$currentLevel',
                          style: AppTheme.bigNum(32, color: AppTheme.bg)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHALLENGER',
                            style: AppTheme.bigNum(20, color: AppTheme.voltLime)
                                .copyWith(letterSpacing: 0.3)),
                        Text('Level 20 — 35 · Mid-tier athlete',
                            style: AppTheme.label(11, color: AppTheme.ink2)),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('14,200 / 21,000 XP',
                                style: AppTheme.label(10, color: AppTheme.ink2)),
                            Text('6.8K to LV ${currentLevel + 1}',
                                style: AppTheme.label(10, color: AppTheme.ink2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              Text('LEVEL PATH',
                  style: AppTheme.label(10, color: AppTheme.ink2).copyWith(
                      letterSpacing: 1.2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              ...[
                [1, 'Walker', true],
                [10, 'Mover', true],
                [20, 'Challenger', true],
                [35, 'Athlete', false],
                [50, 'Elite', false],
                [75, 'Legend', false],
                [100, 'Immortal', false],
              ].map((row) {
                final lv = row[0] as int;
                final title = row[1] as String;
                final done = row[2] as bool;
                final isCurrent = lv == 20;
                return Opacity(
                  opacity: done ? 1.0 : 0.55,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.voltLime.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.voltLime.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 50,
                        child: Text('LV$lv',
                            style: AppTheme.bigNum(18,
                                color: done
                                    ? AppTheme.voltLime
                                    : AppTheme.ink3)),
                      ),
                      Expanded(
                        child: Text(title,
                            style: AppTheme.label(14, color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Icon(
                        done
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        color: done ? AppTheme.voltLime : AppTheme.ink3,
                        size: 18,
                      ),
                    ]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
