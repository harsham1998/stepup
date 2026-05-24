import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../shared/widgets/challenge_card.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});
  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String _activityFilter = 'All';

  static const _activityTabs = [
    ('All', '🏆'),
    ('steps', '👟'),
    ('running', '🏃'),
    ('gym', '💪'),
    ('outdoor', '⚽'),
    ('cycling', '🚴'),
    ('walking', '🚶'),
  ];

  List<Challenge> _applyFilter(List<Challenge> all) {
    if (_activityFilter == 'All') return all;
    return all.where((c) => c.activityType == _activityFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(activeChallengesProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _Header(),
          const SizedBox(height: 12),
          _ActivityFilterRow(
            selected: _activityFilter,
            tabs: _activityTabs,
            onSelect: (v) => setState(() => _activityFilter = v),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: challengesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, color: Color(0xFF4B5563), size: 40),
                  const SizedBox(height: 8),
                  Text('$e', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      textAlign: TextAlign.center),
                ]),
              ),
              data: (all) {
                final filtered = _applyFilter(all);
                final live = filtered.where((c) => c.isLive).toList();
                final upcoming = filtered.where((c) => !c.isLive).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('🏋️', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text('No challenges in this category',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    ]),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (live.isNotEmpty) ...[
                      _SectionHeader(label: 'LIVE NOW', count: live.length, dotColor: const Color(0xFFEF4444)),
                      const SizedBox(height: 8),
                      ...live.map((c) => ChallengeCard(
                        challenge: c,
                        onTap: () => context.push('/challenges/${c.id}'),
                      )),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      if (live.isNotEmpty) const SizedBox(height: 8),
                      _SectionHeader(label: 'COMING UP', count: upcoming.length, dotColor: const Color(0xFF6366F1)),
                      const SizedBox(height: 8),
                      ...upcoming.map((c) => ChallengeCard(
                        challenge: c,
                        onTap: () => context.push('/challenges/${c.id}'),
                      )),
                    ],
                  ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Row(children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Discover', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
        Text('Challenges ⚔️',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(children: [
          Icon(Icons.circle, color: Color(0xFFEF4444), size: 6),
          SizedBox(width: 5),
          Text('LIVE', style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      ),
    ]),
  );
}

class _ActivityFilterRow extends StatelessWidget {
  final String selected;
  final List<(String, String)> tabs;
  final ValueChanged<String> onSelect;
  const _ActivityFilterRow({required this.selected, required this.tabs, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: tabs.map((tab) {
        final (value, emoji) = tab;
        final isAll = value == 'All';
        final label = isAll ? 'All' : _capitalize(value);
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onSelect(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(emoji, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  )),
            ]),
          ),
        );
      }).toList(),
    ),
  );

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color dotColor;
  const _SectionHeader({required this.label, required this.count, required this.dotColor});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 6, height: 6,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label,
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10,
            fontWeight: FontWeight.w800, letterSpacing: 0.8)),
    const SizedBox(width: 6),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count',
          style: TextStyle(color: dotColor, fontSize: 9, fontWeight: FontWeight.w800)),
    ),
  ]);
}
