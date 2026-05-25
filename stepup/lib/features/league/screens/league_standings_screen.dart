import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/league_provider.dart';
import '../../../core/theme.dart';

class LeagueStandingsScreen extends ConsumerWidget {
  const LeagueStandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(leagueStandingsProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Standings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: standingsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.voltLime)),
        error: (e, _) => Center(
            child: Text('$e', style: const TextStyle(color: Colors.white))),
        data: (data) {
          final entries =
              (data['entries'] as List? ?? []);
          final total =
              data['total_in_league'] as int? ?? 0;
          final promoteCount =
              total > 0 ? (total * 0.25).floor() : 0;
          final relegateStart =
              total > 0 ? total - (total * 0.15).floor() : 0;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                const Icon(Icons.access_time_rounded,
                    color: AppTheme.ink3, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Resets end of season · top 25% promote · bottom 15% relegate',
                    style: AppTheme.label(11),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: entries.length,
                itemBuilder: (ctx, i) {
                  final e = entries[i] as Map<String, dynamic>;
                  final rank = (e['rank'] as num).toInt();
                  final isMe = e['is_me'] as bool? ?? false;
                  final inPromote =
                      promoteCount > 0 && rank <= promoteCount;
                  final inRelegate =
                      relegateStart > 0 && rank > relegateStart;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppTheme.voltLime.withOpacity(0.08)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMe
                            ? AppTheme.voltLime.withOpacity(0.5)
                            : inPromote
                                ? const Color(0xFF22C55E)
                                    .withOpacity(0.25)
                                : inRelegate
                                    ? const Color(0xFFEF4444)
                                        .withOpacity(0.2)
                                    : AppTheme.border,
                      ),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          '#$rank',
                          style: AppTheme.bigNum(18,
                              color: isMe
                                  ? AppTheme.voltLime
                                  : AppTheme.ink2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['name'] as String? ?? 'Unknown',
                                style: AppTheme.label(14,
                                        color: isMe
                                            ? Colors.white
                                            : AppTheme.ink2)
                                    .copyWith(
                                        fontWeight: FontWeight.w600),
                              ),
                              Text('${e['xp']} XP',
                                  style: AppTheme.label(11)),
                            ]),
                      ),
                      if (inPromote)
                        const Icon(Icons.arrow_upward_rounded,
                            color: Color(0xFF22C55E), size: 16),
                      if (inRelegate && !inPromote)
                        const Icon(Icons.arrow_downward_rounded,
                            color: Color(0xFFEF4444), size: 16),
                    ]),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}
