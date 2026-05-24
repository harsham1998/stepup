import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../challenges/providers/challenges_provider.dart';
import '../../steps/step_sync_service.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../providers/home_provider.dart';
import '../../../shared/widgets/step_ring_widget.dart';
import '../../../shared/widgets/challenge_card.dart';
import '../../../core/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestHealthPermissions();
  }

  Future<void> _requestHealthPermissions() async {
    try {
      await StepSyncService.instance.requestPermissions();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final stepsAsync = ref.watch(dailyStepsProvider);
    final walletAsync = ref.watch(walletBalanceProvider);
    final challengesAsync = ref.watch(activeChallengesProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // Greeting row
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Good morning,',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                    Text('StepUp 👋',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ]),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Step card
                stepsAsync.when(
                  loading: () => const _StepCardSkeleton(),
                  error: (_, e) => const _StepCardSkeleton(),
                  data: (steps) => _StepCard(steps: steps, goal: 10000),
                ),
                const SizedBox(height: 10),

                // Stats row
                walletAsync.when(
                  loading: () => const SizedBox(height: 64),
                  error: (_, e) => const SizedBox(height: 64),
                  data: (wallet) => Row(children: [
                    _StatBox(label: 'Rank', value: '#-', color: AppTheme.amber),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: 'Wallet',
                      value: '₹${wallet['balance_inr'] ?? '0'}',
                      color: AppTheme.green,
                    ),
                    const SizedBox(width: 8),
                    _StatBox(label: 'Streak', value: '🔥 0', color: AppTheme.pink),
                  ]),
                ),
                const SizedBox(height: 10),

                // Health shortcut card
                GestureDetector(
                  onTap: () => context.push('/health'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Health & Activity',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          Text('Steps · Distance · Calories · Heart Rate · Workouts',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
                        ]),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF374151), size: 12),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),

                // Section header
                Row(children: [
                  const Text('LIVE CHALLENGES',
                      style: TextStyle(color: Color(0xFF4B5563), fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/challenges'),
                    child: const Text('See all',
                        style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 8),

                // Active challenges
                challengesAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, e) => const SizedBox(),
                  data: (challenges) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: challenges.take(3).map((c) =>
                        ChallengeCard(
                          challenge: c,
                          onTap: () => context.push('/challenges/${c.id}'),
                        )).toList(),
                  ),
                ),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int steps, goal;
  const _StepCard({required this.steps, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF2D2262)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TODAY\'S STEPS',
              style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
          Text(
            _formatSteps(steps),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
          ),
          const SizedBox(height: 3),
          Text(
            goal - steps > 0 ? '${_formatSteps(goal - steps)} more to goal' : 'Goal reached! 🎉',
            style: const TextStyle(color: Color(0xFF6366F1), fontSize: 10),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (steps / goal).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              minHeight: 5,
            ),
          ),
        ])),
        const SizedBox(width: 12),
        StepRingWidget(currentSteps: steps, goalSteps: goal, size: 72),
      ]),
    );
  }

  String _formatSteps(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _StepCardSkeleton extends StatelessWidget {
  const _StepCardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 110,
    decoration: BoxDecoration(
      color: const Color(0xFF1E1B4B),
      borderRadius: BorderRadius.circular(14),
    ),
  );
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 9)),
      ]),
    ),
  );
}
