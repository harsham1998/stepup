import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../wallet/providers/wallet_provider.dart';

class HomeCoinsBanner extends ConsumerWidget {
  const HomeCoinsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletBalanceProvider);
    final coins = walletAsync.whenOrNull(
          data: (w) => (w['coin_balance'] as num?)?.toInt() ?? 0,
        ) ??
        0;

    return GestureDetector(
      onTap: () => context.push('/coins/battlepass'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.amber.withValues(alpha: 0.15),
            ),
            child: const Center(
              child: Icon(Icons.monetization_on_rounded,
                  color: AppTheme.amber, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _fmtCoins(coins),
              style: GoogleFonts.bigShouldersDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.amber),
            ),
            Text(
              '≈ ₹${(coins / 100).toStringAsFixed(0)} in rewards',
              style: AppTheme.label(11, color: AppTheme.ink2),
            ),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.amber.withValues(alpha: 0.22)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Redeem',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.amber)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 12, color: AppTheme.amber),
            ]),
          ),
        ]),
      ),
    );
  }

  String _fmtCoins(int c) {
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(c % 1000 == 0 ? 0 : 1)}K ¢';
    return '$c ¢';
  }
}
