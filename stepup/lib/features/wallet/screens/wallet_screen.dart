import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';
import '../../../shared/models/wallet_transaction.dart';
import '../../../core/theme.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final txnsAsync = ref.watch(walletTransactionsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Wallet',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),

            // Balance card
            balanceAsync.when(
              loading: () => Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: const Text('Could not load balance',
                    style: TextStyle(color: Color(0xFFF87171), fontSize: 12)),
              ),
              data: (w) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.green.withValues(alpha: 0.25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('TOTAL BALANCE',
                      style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 9,
                          letterSpacing: 0.8, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('₹${w['balance_inr'] ?? '0'}',
                      style: const TextStyle(color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                      ),
                      child: const Text('Withdraw UPI', style: TextStyle(fontSize: 11)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.green,
                        side: BorderSide(color: AppTheme.green.withValues(alpha: 0.4)),
                      ),
                      child: const Text('Add Money', style: TextStyle(fontSize: 11)),
                    )),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            const Text('RECENT ACTIVITY',
                style: TextStyle(color: Color(0xFF4B5563), fontSize: 9,
                    letterSpacing: 0.8, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            Expanded(child: txnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(
                child: Text('Could not load transactions',
                    style: TextStyle(color: Color(0xFF6B7280))),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet',
                        style: TextStyle(color: Color(0xFF6B7280))),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final t = WalletTransaction.fromJson(list[i] as Map<String, dynamic>);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: t.isCredit
                                ? AppTheme.green.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            t.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 14,
                            color: t.isCredit ? AppTheme.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.description,
                                style: const TextStyle(color: Color(0xFFD1D5DB),
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(
                              '${t.createdAt.toLocal().year}-'
                              '${t.createdAt.toLocal().month.toString().padLeft(2, '0')}-'
                              '${t.createdAt.toLocal().day.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 10),
                            ),
                          ],
                        )),
                        Text(t.amountInr,
                            style: TextStyle(
                              color: t.isCredit ? AppTheme.green : const Color(0xFFEF4444),
                              fontSize: 12, fontWeight: FontWeight.w700,
                            )),
                      ]),
                    );
                  },
                );
              },
            )),
          ]),
        ),
      ),
    );
  }
}
