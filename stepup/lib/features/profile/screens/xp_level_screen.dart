import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/xp_level_provider.dart';
import '../../../shared/models/xp_level.dart';
import '../../../core/theme.dart';

class XpLevelScreen extends ConsumerWidget {
  const XpLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(xpLevelProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(child: Text('Error: $e', style: AppTheme.label(13, color: AppTheme.ink2))),
          data: (xp) => _XpBody(xp: xp),
        ),
      ),
    );
  }
}

class _XpBody extends StatelessWidget {
  final XpLevel xp;
  const _XpBody({required this.xp});

  @override
  Widget build(BuildContext context) {
    final progress = xp.xpInCurrentLevel / xp.xpForNextLevel.clamp(1, double.maxFinite).toInt();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
              Text('LV ${xp.level} → ${xp.level + 1}',
                  style: AppTheme.label(12, color: AppTheme.ink2)),
            ],
          ),
          const SizedBox(height: 16),
          Text('LEVEL', style: AppTheme.bigNum(22).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [
                AppTheme.voltLime.withValues(alpha: 0.10),
                AppTheme.amber.withValues(alpha: 0.04),
              ]),
            ),
            child: Row(children: [
              Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppTheme.voltLime, Color(0x33D4FF3A)]),
                ),
                child: Center(child: Text('${xp.level}', style: AppTheme.bigNum(32, color: AppTheme.bg))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(xp.title.toUpperCase(),
                    style: AppTheme.bigNum(20, color: AppTheme.voltLime).copyWith(letterSpacing: 0.3)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${_fmt(xp.xp)} / ${_fmt(xp.xpForNextLevel)} XP',
                      style: AppTheme.label(10, color: AppTheme.ink2)),
                  Text('${_fmt(xp.xpNeeded)} to LV ${xp.level + 1}',
                      style: AppTheme.label(10, color: AppTheme.ink2)),
                ]),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          Text('LEVEL PATH',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...[
            [1, 'Walker'], [10, 'Mover'], [20, 'Challenger'],
            [35, 'Athlete'], [50, 'Elite'], [75, 'Legend'], [100, 'Immortal'],
          ].map((row) {
            final lv = row[0] as int;
            final title = row[1] as String;
            final done = xp.level >= lv;
            final isCurrent = (lv <= xp.level) &&
                (lv == 100 || xp.level < ([1,10,20,35,50,75,100].firstWhere((b) => b > lv, orElse: () => 101)));
            return Opacity(
              opacity: done ? 1.0 : 0.55,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.voltLime.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? AppTheme.voltLime.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 50,
                    child: Text('LV$lv',
                        style: AppTheme.bigNum(18, color: done ? AppTheme.voltLime : AppTheme.ink3)),
                  ),
                  Expanded(child: Text(title,
                      style: AppTheme.label(14, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600))),
                  Icon(done ? Icons.check_circle_rounded : Icons.lock_rounded,
                      color: done ? AppTheme.voltLime : AppTheme.ink3, size: 18),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
