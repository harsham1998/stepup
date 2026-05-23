import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/widgets/challenge_card.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});
  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(activeChallengesProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Battles ⚔️',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B5563).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Live',
                      style: TextStyle(color: Color(0xFFF87171), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'Free', 'Paid', 'Team', 'City'].map((label) {
                    final selected = _filter == label;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = label),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF6366F1)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF6B7280),
                              fontSize: 11, fontWeight: FontWeight.w700,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: challengesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Failed to load: $e',
                      style: const TextStyle(color: Color(0xFF9CA3AF))),
                ),
                data: (list) {
                  final filtered = _filter == 'All' ? list : list.where((c) {
                    if (_filter == 'Free') return !c.isPaid;
                    if (_filter == 'Paid') return c.isPaid;
                    return c.type.toLowerCase().contains(_filter.toLowerCase());
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No challenges found',
                          style: TextStyle(color: Color(0xFF6B7280))),
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => ChallengeCard(
                      challenge: filtered[i],
                      onTap: () => context.push('/challenges/${filtered[i].id}'),
                    ),
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}
