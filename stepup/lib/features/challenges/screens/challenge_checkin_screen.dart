import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../core/theme.dart';

class ChallengeCheckinScreen extends ConsumerWidget {
  final String id;
  const ChallengeCheckinScreen({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailProvider(id));
    final progressAsync = ref.watch(challengeProgressProvider(id));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: challengeAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(child: Text('$e', style: AppTheme.label(13))),
          data: (challenge) => progressAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
            error: (e, _) => Center(child: Text('$e', style: AppTheme.label(13))),
            data: (progress) {
              if (progress == null) {
                return Center(
                  child: Text("You haven't joined this challenge.",
                      style: AppTheme.label(14, color: AppTheme.ink2)),
                );
              }
              return _CheckinBody(challenge: challenge, progress: progress);
            },
          ),
        ),
      ),
    );
  }
}

class _CheckinBody extends StatelessWidget {
  final Challenge challenge;
  final ChallengeProgress progress;

  const _CheckinBody({required this.challenge, required this.progress});

  @override
  Widget build(BuildContext context) {
    final int totalDays = progress.totalDays;
    final int daysPassed = progress.daysPassed;
    final bool completedToday = progress.completedToday;
    final List<bool> checkins = progress.dailyCheckins;

    final windowSize = totalDays.clamp(1, 7);
    final windowStart = (daysPassed - windowSize + 1).clamp(0, daysPassed);
    final windowCheckins = checkins.length >= windowStart + windowSize
        ? checkins.sublist(windowStart, windowStart + windowSize)
        : checkins.length > windowStart
            ? checkins.sublist(windowStart)
            : <bool>[];

    final weekDayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final progressPct = progress.percent;
    final int currentVal = progress.current;
    final int goalVal = progress.goal;
    final String actType = progress.activityType;
    final int prizePool = progress.prizePool;

    String progressText;
    if (['gym', 'cycling', 'outdoor'].contains(actType)) {
      progressText = '$currentVal / $goalVal sessions';
    } else {
      final cur = currentVal >= 1000
          ? '${(currentVal / 1000).toStringAsFixed(1)}k'
          : '$currentVal';
      final goal =
          goalVal >= 1000 ? '${(goalVal / 1000).toStringAsFixed(0)}k' : '$goalVal';
      progressText = '$cur / $goal steps';
    }

    return Padding(
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
              Text('Day $daysPassed of $totalDays',
                  style: AppTheme.label(13, color: AppTheme.ink2)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Check in', style: AppTheme.bigNum(28)),
          const SizedBox(height: 4),
          Text(
            '${challenge.title} · today\'s status',
            style: AppTheme.label(13, color: AppTheme.ink2),
          ),
          const SizedBox(height: 24),

          Center(
            child: Column(children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completedToday
                      ? AppTheme.voltLime.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: completedToday ? AppTheme.voltLime : AppTheme.border,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    completedToday ? '✓' : '○',
                    style: AppTheme.bigNum(
                      44,
                      color: completedToday ? AppTheme.voltLime : AppTheme.ink2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                completedToday ? 'Done today!' : 'Not yet today',
                style: AppTheme.bigNum(22),
              ),
              const SizedBox(height: 4),
              Text(
                progressText,
                style: AppTheme.label(12, color: AppTheme.ink2),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),

          Text('Recent days',
              style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(windowSize, (i) {
              final isDone = i < windowCheckins.length && windowCheckins[i];
              final isToday = i == windowCheckins.length - 1;

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
                borderColor = AppTheme.ink3;
                bgColor = Colors.transparent;
                textColor = AppTheme.ink3;
                label = '';
              }

              final dayIdx = (windowStart + i) % 7;
              return Column(children: [
                Text(weekDayLabels[dayIdx],
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

          const SizedBox(height: 20),
          Text('Overall progress',
              style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progressText, style: AppTheme.label(11, color: AppTheme.ink2)),
              Text('${(progressPct * 100).round()}%',
                  style: AppTheme.label(11, color: AppTheme.voltLime)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),

          const Spacer(),

          if (prizePool > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Finish in top 50% to earn',
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('+${prizePool ~/ 100} ¢',
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
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('View challenge leaderboard →',
                  style: AppTheme.label(13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
