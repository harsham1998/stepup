import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../../shared/models/wallet_transaction.dart';
import '../../../core/theme.dart';

class CoinsScreen extends ConsumerWidget {
  const CoinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final txnAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Coins & Wallet', style: AppTheme.bigNum(28)),
                  const SizedBox(height: 20),

                  // Dual balance cards
                  balanceAsync.when(
                    loading: () => const SizedBox(height: 110),
                    error: (_, __) => const SizedBox(height: 110),
                    data: (w) => Row(children: [
                      Expanded(
                        child: _BalanceCard(
                          label: 'WALLET',
                          value: '₹${w['balance_inr'] ?? 0}',
                          color: AppTheme.green,
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BalanceCard(
                          label: 'COINS',
                          value: '${w['coin_balance'] ?? 0}¢',
                          color: AppTheme.amber,
                          icon: Icons.monetization_on_rounded,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // INR actions
                  Text(
                    'WALLET ACTIONS',
                    style: AppTheme.label(10, color: AppTheme.ink3)
                        .copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _ActionBtn(
                      label: 'Deposit',
                      icon: Icons.add_rounded,
                      color: AppTheme.green,
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _ActionBtn(
                      label: 'Withdraw',
                      icon: Icons.arrow_upward_rounded,
                      color: AppTheme.ink2,
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Coin quick links
                  Text(
                    'EARN & SPEND COINS',
                    style: AppTheme.label(10, color: AppTheme.ink3)
                        .copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _ActionBtn(
                      label: 'Marketplace',
                      icon: Icons.storefront_rounded,
                      color: AppTheme.amber,
                      onTap: () => context.push('/coins/rewards'),
                    ),
                    const SizedBox(width: 10),
                    _ActionBtn(
                      label: 'Battle Pass',
                      icon: Icons.shield_rounded,
                      color: AppTheme.voltLime,
                      onTap: () =>
                          context.push('/coins/battlepass'),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Transaction list
                  Text(
                    'RECENT TRANSACTIONS',
                    style: AppTheme.label(10, color: AppTheme.ink3)
                        .copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  txnAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.voltLime)),
                    error: (e, _) => Text('$e',
                        style:
                            const TextStyle(color: Colors.white)),
                    data: (txns) => txns.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24),
                            child: Center(
                              child: Text('No transactions yet',
                                  style: AppTheme.label(14)),
                            ),
                          )
                        : Column(
                            children: txns
                                .take(20)
                                .map((t) => _TxnRow(
                                    txn: WalletTransaction
                                        .fromJson(
                                            t as Map<String,
                                                dynamic>)))
                                .toList()),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _BalanceCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.label(9, color: color).copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(value,
                  style: AppTheme.bigNum(24, color: Colors.white)),
            ]),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTheme.label(13, color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ]),
          ),
        ),
      );
}

class _TxnRow extends StatelessWidget {
  final WalletTransaction txn;
  const _TxnRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCredit =
        txn.type == 'credit' || txn.type == 'refund';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCredit
                ? AppTheme.green.withOpacity(0.1)
                : const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color:
                isCredit ? AppTheme.green : const Color(0xFFEF4444),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: AppTheme.label(13, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(_fmtDate(txn.createdAt),
                    style: AppTheme.label(11)),
              ]),
        ),
        Text(
          '${isCredit ? '+' : '-'}₹${(txn.amount / 100).toStringAsFixed(0)}',
          style: AppTheme.bigNum(15,
              color: isCredit
                  ? AppTheme.green
                  : const Color(0xFFEF4444)),
        ),
      ]),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
