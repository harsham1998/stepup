import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rewards_provider.dart';
import '../../../shared/models/reward.dart';
import '../../../features/wallet/providers/wallet_provider.dart';
import '../../../core/theme.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  static const _categories = ['All', 'Tech', 'Apparel', 'Nutrition', 'Memberships', 'Vouchers'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(selectedCategoryProvider);
    final rewardsAsync = ref.watch(rewardsProvider(cat.toLowerCase()));
    final walletAsync = ref.watch(walletBalanceProvider);
    final coinBalance = walletAsync.whenOrNull(
          data: (w) => (w['coin_balance'] as num?)?.toInt() ?? 0,
        ) ??
        0;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rewards', style: AppTheme.bigNum(28)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${coinBalance > 0 ? coinBalance : 1240} ¢',
                      style: AppTheme.label(13, color: AppTheme.amber)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final c = _categories[i];
                    final sel = cat.toLowerCase() == c.toLowerCase() ||
                        (cat == 'all' && c == 'All');
                    return GestureDetector(
                      onTap: () => ref.read(selectedCategoryProvider.notifier).state =
                          c.toLowerCase(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.voltLime : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? AppTheme.voltLime
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          c,
                          style: AppTheme.label(11).copyWith(
                            color: sel ? AppTheme.bg : AppTheme.ink2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
          Expanded(
            child: rewardsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (_, __) => const _MockMarketplace(),
              data: (rewards) =>
                  rewards.isEmpty ? const _MockMarketplace() : _RewardsList(rewards: rewards),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RewardsList extends StatelessWidget {
  final List<Reward> rewards;
  const _RewardsList({required this.rewards});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: rewards.length,
          itemBuilder: (_, i) => _RewardCard(reward: rewards[i]),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  const _RewardCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(_categoryIcon(reward.category),
                size: 28, color: AppTheme.ink2),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(reward.title,
              style: AppTheme.label(12, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${reward.coinCost} ¢',
                style: AppTheme.label(12, color: AppTheme.amber)),
          ],
        ),
      ]),
    );
  }

  static IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'watch':
      case 'tech':
        return Icons.watch_rounded;
      case 'shoes':
      case 'apparel':
        return Icons.directions_run_rounded;
      case 'protein':
      case 'nutrition':
        return Icons.fitness_center_rounded;
      case 'gym':
      case 'memberships':
        return Icons.sports_gymnastics_rounded;
      case 'voucher':
      case 'vouchers':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.redeem_rounded;
    }
  }
}

class _MockMarketplace extends StatelessWidget {
  const _MockMarketplace();

  static const _items = [
    ['Nike Run Shoes', 'apparel', 12000],
    ['Cult.fit · 3mo', 'memberships', 8400],
    ['MyProtein · 1kg', 'nutrition', 3200],
    ['Amazon ₹500', 'vouchers', 2500],
    ['boAt Watch', 'tech', 4800],
    ['Yoga Mat · Premium', 'apparel', 1200],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(children: [
        // Featured hero
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x1AFFB547), Color(0x0AD4FF3A)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.amber.withValues(alpha: 0.25)),
          ),
          child: Stack(children: [
            Positioned(
              top: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('ELITE',
                    style: AppTheme.label(9, color: AppTheme.amber)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.watch_rounded, color: AppTheme.amber, size: 36),
              const SizedBox(height: 8),
              Text('APPLE WATCH\nSERIES 10',
                  style: AppTheme.bigNum(22)),
              const SizedBox(height: 6),
              Text('Elite tier exclusive · ships in 5 days',
                  style: AppTheme.label(11, color: AppTheme.ink2)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('48,000 ¢',
                      style: AppTheme.bigNum(22, color: AppTheme.amber)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Reach Elite →',
                        style: AppTheme.label(11, color: AppTheme.ink2)),
                  ),
                ],
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerLeft,
          child: Text('YOU CAN REDEEM',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final item = _items[i];
            final name = item[0] as String;
            final cat = item[1] as String;
            final cost = item[2] as int;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(_categoryIcon(cat), size: 28, color: AppTheme.ink2),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(name,
                      style: AppTheme.label(12, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const Spacer(),
                Row(children: [
                  Text('$cost ¢',
                      style: AppTheme.label(12, color: AppTheme.amber)),
                ]),
              ]),
            );
          },
        ),
      ]),
    );
  }

  static IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'tech':
        return Icons.watch_rounded;
      case 'apparel':
        return Icons.directions_run_rounded;
      case 'nutrition':
        return Icons.fitness_center_rounded;
      case 'memberships':
        return Icons.sports_gymnastics_rounded;
      case 'vouchers':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.redeem_rounded;
    }
  }
}
