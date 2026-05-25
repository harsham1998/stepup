import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../shared/widgets/challenge_card.dart';
import '../../../core/theme.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});
  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String _activityFilter = 'All';

  static const _activityTabs = [
    'All',
    'Steps',
    'Gym',
    'Yoga',
    'Sport',
    'Streak',
  ];

  List<Challenge> _applyFilter(List<Challenge> all) {
    if (_activityFilter == 'All') return all;
    return all
        .where((c) =>
            c.activityType.toLowerCase() == _activityFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(activeChallengesProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: AppTheme.ink3, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    style: AppTheme.label(12, color: AppTheme.ink2),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
              data: (all) {
                final filtered = _applyFilter(all);
                final live = filtered.where((c) => c.isLive).toList();
                final upcoming =
                    filtered.where((c) => !c.isLive).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🏋️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        'No challenges in this category',
                        style: AppTheme.label(13, color: AppTheme.ink2),
                      ),
                    ]),
                  );
                }

                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Create your own challenge CTA
                    GestureDetector(
                      onTap: () =>
                          context.push('/challenges/custom/new'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.voltLime.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.voltLime
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '+ Create your own challenge',
                                    style:
                                        AppTheme.label(14, color: Colors.white)
                                            .copyWith(
                                                fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Invite friends · system sets the reward',
                                    style: AppTheme.label(11,
                                        color: AppTheme.ink2),
                                  ),
                                ]),
                          ),
                          Text('→',
                              style: AppTheme.bigNum(22,
                                  color: AppTheme.voltLime)),
                        ]),
                      ),
                    ),

                    // For you section header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'For you',
                        style: AppTheme.label(12, color: AppTheme.ink3)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),

                    if (live.isNotEmpty) ...[
                      _SectionHeader(
                          label: 'LIVE NOW',
                          count: live.length,
                          dotColor: const Color(0xFFEF4444)),
                      const SizedBox(height: 8),
                      ...live.map((c) => ChallengeCard(
                            challenge: c,
                            onTap: () =>
                                context.push('/challenges/${c.id}'),
                          )),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      if (live.isNotEmpty) const SizedBox(height: 8),
                      _SectionHeader(
                          label: 'COMING UP',
                          count: upcoming.length,
                          dotColor: AppTheme.voltLime),
                      const SizedBox(height: 8),
                      ...upcoming.map((c) => ChallengeCard(
                            challenge: c,
                            onTap: () =>
                                context.push('/challenges/${c.id}'),
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Discover',
                style: AppTheme.label(11, color: AppTheme.ink3)),
            Text('Challenges',
                style: AppTheme.bigNum(20)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Icon(Icons.circle,
                  color: Color(0xFFEF4444), size: 6),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: AppTheme.label(10, color: const Color(0xFFEF4444))
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ]),
          ),
        ]),
      );
}

class _ActivityFilterRow extends StatelessWidget {
  final String selected;
  final List<String> tabs;
  final ValueChanged<String> onSelect;
  const _ActivityFilterRow(
      {required this.selected,
      required this.tabs,
      required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: tabs.map((tab) {
            final isSelected = selected == tab;
            return GestureDetector(
              onTap: () => onSelect(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.voltLime
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.voltLime
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  tab,
                  style: AppTheme.label(11).copyWith(
                    color: isSelected ? AppTheme.bg : AppTheme.ink2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color dotColor;
  const _SectionHeader(
      {required this.label,
      required this.count,
      required this.dotColor});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
              fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
        const SizedBox(width: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: dotColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTheme.label(9, color: dotColor)
                .copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ]);
}
