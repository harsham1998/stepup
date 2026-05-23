import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leaderboard_provider.dart';
import '../../../shared/models/leaderboard_entry.dart';
import '../../../core/theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final _tabCtrl = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lbAsync = ref.watch(globalLeaderboardProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rankings',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF374151),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Global'), Tab(text: 'Friends'), Tab(text: 'City')],
                ),
              ),
            ]),
          ),
          Expanded(child: lbAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('$e', style: const TextStyle(color: Color(0xFF9CA3AF))),
            ),
            data: (entries) => entries.isEmpty
                ? const Center(
                    child: Text('No rankings yet',
                        style: TextStyle(color: Color(0xFF6B7280))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _LeaderboardRow(entry: entries[i]),
                  ),
          )),
        ]),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final medals = ['🥇', '🥈', '🥉'];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Text(
            isTop3 ? medals[entry.rank - 1] : '#${entry.rank}',
            style: TextStyle(
              fontSize: isTop3 ? 18 : 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primary,
          child: Text(
            entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.name,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          Text('${entry.steps} steps',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
        ])),
      ]),
    );
  }
}
