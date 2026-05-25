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

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static const _categoryIcons = {
    'steps': Icons.directions_walk_rounded,
    'streak': Icons.local_fire_department_rounded,
    'gym': Icons.fitness_center_rounded,
    'chal': Icons.emoji_events_rounded,
    'coins': Icons.monetization_on_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(achievementsProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text('Achievements', style: AppTheme.bigNum(24)),
            ]),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (_, __) => _MockAchievements(),
              data: (list) => list.isEmpty
                  ? _MockAchievements()
                  : _AchievementGrid(achievements: list),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  const _AchievementGrid({required this.achievements});

  static const _categoryIcons = {
    'steps': Icons.directions_walk_rounded,
    'streak': Icons.local_fire_department_rounded,
    'gym': Icons.fitness_center_rounded,
    'chal': Icons.emoji_events_rounded,
    'coins': Icons.monetization_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (_, i) {
        final a = achievements[i];
        final earned = a['earned'] as bool? ?? false;
        final icon = _categoryIcons[a['category']] ??
            Icons.military_tech_rounded;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: earned
                ? AppTheme.voltLime.withValues(alpha: 0.08)
                : AppTheme.surface,
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
                width: 44,
                height: 44,
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
                a['title'] as String,
                style: AppTheme.label(10, color: earned ? Colors.white : AppTheme.ink2)
                    .copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (earned) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 10, color: AppTheme.voltLime),
                    const SizedBox(width: 2),
                    Text('Earned',
                        style: AppTheme.label(9, color: AppTheme.voltLime)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text('+${a['coin_reward']}¢',
                    style: AppTheme.label(9, color: AppTheme.amber)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Shown when DB table doesn't exist yet / empty
class _MockAchievements extends StatelessWidget {
  static const _items = [
    ['First Step', 'steps', true, '10¢'],
    ['Week Warrior', 'streak', true, '25¢'],
    ['Gym Regular', 'gym', false, '40¢'],
    ['Challenger', 'chal', false, '100¢'],
    ['Coin Collector', 'coins', false, '0¢'],
    ['Month Master', 'streak', false, '150¢'],
    ['100K Walker', 'steps', false, '50¢'],
    ['Top Performer', 'chal', false, '75¢'],
    ['Challenge King', 'chal', false, '300¢'],
  ];

  static const _categoryIcons = {
    'steps': Icons.directions_walk_rounded,
    'streak': Icons.local_fire_department_rounded,
    'gym': Icons.fitness_center_rounded,
    'chal': Icons.emoji_events_rounded,
    'coins': Icons.monetization_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final item = _items[i];
        final earned = item[2] as bool;
        final icon = _categoryIcons[item[1]] ?? Icons.military_tech_rounded;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: earned
                ? AppTheme.voltLime.withValues(alpha: 0.08)
                : AppTheme.surface,
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
                width: 44,
                height: 44,
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
                item[0] as String,
                style: AppTheme.label(10,
                        color: earned ? Colors.white : AppTheme.ink2)
                    .copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              if (earned) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_rounded,
                      size: 10, color: AppTheme.voltLime),
                  const SizedBox(width: 2),
                  Text('Earned',
                      style: AppTheme.label(9, color: AppTheme.voltLime)),
                ]),
              ] else ...[
                const SizedBox(height: 4),
                Text(item[3] as String,
                    style: AppTheme.label(9, color: AppTheme.amber)),
              ],
            ],
          ),
        );
      },
    );
  }
}
