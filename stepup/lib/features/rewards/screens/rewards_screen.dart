import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/rewards_provider.dart';
import '../../../shared/models/reward.dart';
import '../../../features/wallet/providers/wallet_provider.dart';
import '../../../core/theme.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  static const _categories = [
    'all',
    'watch',
    'shoes',
    'protein',
    'gym',
    'voucher',
    'wellness'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(selectedCategoryProvider);
    final rewardsAsync = ref.watch(rewardsProvider(cat));
    final walletAsync = ref.watch(walletBalanceProvider);

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
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Text('Marketplace', style: AppTheme.bigNum(26)),
                    const Spacer(),
                    walletAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (w) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          const Icon(Icons.monetization_on_rounded,
                              color: AppTheme.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${w['coin_balance'] ?? 0}¢',
                            style: AppTheme.bigNum(14,
                                color: AppTheme.amber),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = _categories[i];
                        final sel = cat == c;
                        return GestureDetector(
                          onTap: () => ref
                              .read(selectedCategoryProvider.notifier)
                              .state = c,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.voltLime
                                  : AppTheme.surface,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel
                                      ? AppTheme.voltLime
                                      : AppTheme.border),
                            ),
                            child: Text(
                              c[0].toUpperCase() + c.substring(1),
                              style: AppTheme.label(12,
                                      color: sel
                                          ? AppTheme.bg
                                          : AppTheme.ink2)
                                  .copyWith(
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.normal),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
          ),
          Expanded(
            child: rewardsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.voltLime)),
              error: (e, _) => Center(
                  child: Text('$e',
                      style:
                          const TextStyle(color: Colors.white))),
              data: (rewards) => rewards.isEmpty
                  ? Center(
                      child: Text(
                          'No rewards in this category',
                          style: AppTheme.label(14)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          20, 8, 20, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: rewards.length,
                      itemBuilder: (_, i) {
                        final coinBal =
                            (walletAsync.value?['coin_balance']
                                    as num?)
                                ?.toInt() ??
                            0;
                        return _RewardCard(
                            reward: rewards[i],
                            coinBalance: coinBal);
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final int coinBalance;
  const _RewardCard(
      {required this.reward, required this.coinBalance});

  bool get canAfford => coinBalance >= reward.coinCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  _categoryIcon(reward.category),
                  size: 48,
                  color: AppTheme.ink3,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.brand,
                      style: AppTheme.label(10,
                              color: AppTheme.ink3)
                          .copyWith(
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700),
                    ),
                    Text(
                      reward.title,
                      style: AppTheme.label(12,
                              color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${reward.coinCost}¢',
                          style: AppTheme.bigNum(16,
                              color: canAfford
                                  ? AppTheme.amber
                                  : AppTheme.ink3),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? AppTheme.voltLime
                                : AppTheme.surface2,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Redeem',
                            style: AppTheme.label(11,
                                    color: canAfford
                                        ? AppTheme.bg
                                        : AppTheme.ink3)
                                .copyWith(
                                    fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ]),
            ),
          ]),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'watch':
        return Icons.watch_rounded;
      case 'shoes':
        return Icons.directions_run_rounded;
      case 'protein':
        return Icons.fitness_center_rounded;
      case 'gym':
        return Icons.sports_gymnastics_rounded;
      case 'voucher':
        return Icons.card_giftcard_rounded;
      case 'wellness':
        return Icons.spa_rounded;
      default:
        return Icons.redeem_rounded;
    }
  }
}
