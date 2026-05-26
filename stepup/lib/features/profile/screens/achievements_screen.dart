import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';

final achievementsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final allAchievements = await Supabase.instance.client
      .from('achievements')
      .select('*')
      .order('xp_reward');
  final earned = await Supabase.instance.client
      .from('user_achievements')
      .select('achievement_id, earned_at')
      .eq('user_id', userId);
  final earnedIds = <String>{};
  final earnedMap = <String, String>{};
  for (final e in (earned as List)) {
    earnedIds.add(e['achievement_id'] as String);
    earnedMap[e['achievement_id'] as String] = e['earned_at'] as String;
  }
  return (allAchievements as List).map((a) {
    final map = Map<String, dynamic>.from(a as Map);
    map['earned'] = earnedIds.contains(a['id']);
    map['earned_at'] = earnedMap[a['id']];
    return map;
  }).toList();
});

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState
    extends ConsumerState<AchievementsScreen> {
  bool _showEarned = true;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(achievementsProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
                const Spacer(),
                async.maybeWhen(
                  data: (list) {
                    final earned = list.where((a) => a['earned'] as bool? ?? false).length;
                    return Text('$earned / ${list.length}',
                        style: AppTheme.label(13, color: AppTheme.ink2));
                  },
                  orElse: () => Text('14 / 36',
                      style: AppTheme.label(13, color: AppTheme.ink2)),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Achievements', style: AppTheme.bigNum(28)),
              const SizedBox(height: 10),
              // Earned / Locked filter chips
              Row(children: [
                GestureDetector(
                  onTap: () => setState(() => _showEarned = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _showEarned
                          ? AppTheme.voltLime
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showEarned
                            ? AppTheme.voltLime
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text('Earned',
                        style: AppTheme.label(12).copyWith(
                          color: _showEarned ? AppTheme.bg : AppTheme.ink2,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showEarned = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: !_showEarned
                          ? AppTheme.voltLime
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !_showEarned
                            ? AppTheme.voltLime
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text('Locked',
                        style: AppTheme.label(12).copyWith(
                          color: !_showEarned ? AppTheme.bg : AppTheme.ink2,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ]),
            ]),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.voltLime)),
              error: (_, __) => _MockAchievementsGrid(showEarned: _showEarned),
              data: (list) => list.isEmpty
                  ? _MockAchievementsGrid(showEarned: _showEarned)
                  : _AchievementGrid(
                      achievements: list, showEarned: _showEarned),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final bool showEarned;
  const _AchievementGrid(
      {required this.achievements, required this.showEarned});

  static const _categoryIcons = {
    'steps': Icons.directions_walk_rounded,
    'streak': Icons.local_fire_department_rounded,
    'gym': Icons.fitness_center_rounded,
    'chal': Icons.emoji_events_rounded,
    'coins': Icons.monetization_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final filtered = achievements
        .where((a) => (a['earned'] as bool? ?? false) == showEarned)
        .toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final a = filtered[i];
        final earned = a['earned'] as bool? ?? false;
        final icon = _categoryIcons[a['category']] ??
            Icons.military_tech_rounded;
        return _AchievementCell(
          label: a['title'] as String? ?? '',
          icon: icon,
          earned: earned,
        );
      },
    );
  }
}

class _AchievementCell extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool earned;
  const _AchievementCell({
    required this.label,
    required this.icon,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: earned
              ? AppTheme.voltLime.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: earned
                ? AppTheme.voltLime.withValues(alpha: 0.35)
                : AppTheme.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: earned
                    ? AppTheme.voltLime.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(icon,
                  size: 22,
                  color: earned ? AppTheme.voltLime : AppTheme.ink3),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.label(10,
                      color: earned ? Colors.white : AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!earned) ...[
              const SizedBox(height: 4),
              const Icon(Icons.lock_rounded,
                  size: 12, color: AppTheme.ink3),
            ],
          ],
        ),
      );
}

class _MockAchievementsGrid extends StatelessWidget {
  final bool showEarned;
  const _MockAchievementsGrid({required this.showEarned});

  static const _earned = [
    ['7-Day Streak', Icons.local_fire_department_rounded],
    ['10k Club', Icons.directions_walk_rounded],
    ['Gym Pro', Icons.fitness_center_rounded],
    ['Zen Master', Icons.self_improvement_rounded],
    ['First Challenge', Icons.emoji_events_rounded],
  ];

  static const _locked = [
    ['Top 10%', Icons.emoji_events_rounded],
    ['30-Day Streak', Icons.local_fire_department_rounded],
    ['Early Bird', Icons.wb_sunny_rounded],
    ['Iron Will', Icons.fitness_center_rounded],
  ];

  @override
  Widget build(BuildContext context) {
    final items = showEarned ? _earned : _locked;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _AchievementCell(
        label: items[i][0] as String,
        icon: items[i][1] as IconData,
        earned: showEarned,
      ),
    );
  }
}
