import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../wallet/providers/wallet_provider.dart';
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coins', style: AppTheme.bigNum(28)),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text('History',
                              style: AppTheme.label(12, color: AppTheme.ink2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Balance card
                  balanceAsync.when(
                    loading: () => _BalanceCard(coinBalance: 0),
                    error: (_, __) => _BalanceCard(coinBalance: 0),
                    data: (w) => _BalanceCard(
                      coinBalance: (w['coin_balance'] as num?)?.toInt() ?? 0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Redeem + Earn more buttons
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/coins/rewards'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.amber.withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: Text('Redeem →',
                                style: AppTheme.label(14, color: AppTheme.amber)
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/challenges'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Center(
                            child: Text('Earn more',
                                style: AppTheme.label(14, color: Colors.white)
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Battle Pass banner
                  GestureDetector(
                    onTap: () => context.push('/coins/battlepass'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.voltLime.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.35)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: AppTheme.voltLime, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Battle Pass',
                                style: AppTheme.label(13, color: Colors.white)
                                    .copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 1),
                            Text('Unlock tier rewards · Season 4',
                                style: AppTheme.label(11, color: AppTheme.ink2)),
                          ]),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: AppTheme.ink2, size: 12),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _Squiggle(),
                  const SizedBox(height: 16),

                  // Recent activity
                  Text('Recent activity',
                      style: AppTheme.label(11, color: AppTheme.ink2)
                          .copyWith(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  txnAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.voltLime)),
                    error: (_, __) => _MockTransactions(),
                    data: (txns) => txns.isEmpty
                        ? _MockTransactions()
                        : Column(
                            children: txns
                                .take(20)
                                .map((t) => _TxnRow(txn: t))
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
  final int coinBalance;
  const _BalanceCard({required this.coinBalance});

  @override
  Widget build(BuildContext context) {
    final display = coinBalance > 0 ? _fmt(coinBalance) : '1,240';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Balance', style: AppTheme.label(11, color: AppTheme.ink2)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('¢', style: AppTheme.bigNum(36, color: AppTheme.amber)),
          const SizedBox(width: 4),
          Text(display,
              style: AppTheme.bigNum(52, color: AppTheme.amber)),
        ]),
        const SizedBox(height: 4),
        Text('≈ ₹240 In gift cards · 12 expire in 90 days',
            style: AppTheme.label(11, color: AppTheme.ink2)),
      ]),
    );
  }

  static String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _TxnRow extends StatelessWidget {
  final dynamic txn;
  const _TxnRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final desc = txn['description'] as String? ?? txn.toString();
    final amount = txn['amount'] as num? ?? 0;
    final type = txn['type'] as String? ?? 'credit';
    final isCredit = type == 'credit' || type == 'earn';
    final dateStr = txn['created_at'] as String? ?? '';
    final date = dateStr.isNotEmpty ? _fmtDate(dateStr) : 'Today';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(desc, style: AppTheme.label(13, color: Colors.white)),
            const SizedBox(height: 2),
            Text(date, style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
        ),
        Text(
          '${isCredit ? '+' : ''}${amount.toInt()} ¢',
          style: AppTheme.bigNum(18,
              color: isCredit ? AppTheme.voltLime : const Color(0xFFC97B4E)),
        ),
      ]),
    );
  }

  static String _fmtDate(String s) {
    try {
      final d = DateTime.parse(s);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final now = DateTime.now();
      final diff = now.difference(d).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff <= 6) return '${diff}d ago';
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return 'Recently';
    }
  }
}

class _MockTransactions extends StatelessWidget {
  static const _items = [
    ['Finished "Yoga 5x"', '+200', 'in', 'Today'],
    ['Redeemed Amazon ₹100', '-500', 'out', 'Yesterday'],
    ['Daily check-in bonus', '+10', 'in', '2d ago'],
    ['Invited Priya', '+50', 'in', '3d ago'],
    ['Top 50% — "10k Steps"', '+150', 'in', '4d ago'],
    ['Streak bonus · 7 days', '+70', 'in', '5d ago'],
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: _items.map((item) {
          final isIn = item[2] == 'in';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item[0],
                      style: AppTheme.label(13, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(item[3],
                      style: AppTheme.label(11, color: AppTheme.ink2)),
                ]),
              ),
              Text(
                '${item[1]} ¢',
                style: AppTheme.bigNum(18,
                    color: isIn ? AppTheme.voltLime : const Color(0xFFC97B4E)),
              ),
            ]),
          );
        }).toList(),
      );
}

class _Squiggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            AppTheme.voltLime.withValues(alpha: 0.3),
            AppTheme.voltLime.withValues(alpha: 0.15),
            Colors.transparent,
          ]),
          borderRadius: BorderRadius.circular(1),
        ),
      );
}
