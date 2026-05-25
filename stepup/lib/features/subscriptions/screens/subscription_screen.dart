import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/subscription_provider.dart';
import '../../../shared/models/subscription_plan.dart';
import '../../../core/theme.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final mySubAsync = ref.watch(mySubscriptionProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: plansAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.voltLime)),
          error: (e, _) => Center(
              child: Text('$e',
                  style:
                      const TextStyle(color: Colors.white))),
          data: (plans) {
            final mySub = mySubAsync.value;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        Text('Pick Your Plan',
                            style: AppTheme.bigNum(26)),
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 52, bottom: 20),
                        child: Text(
                            'Upgrade anytime · Cancel anytime',
                            style: AppTheme.label(13)),
                      ),
                      ...plans.map((p) => _PlanCard(
                            plan: p,
                            isCurrent:
                                mySub?.planSlug == p.slug,
                            isRecommended: p.slug == 'beginner',
                          )),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent, isRecommended;
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isRecommended,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isRecommended
        ? AppTheme.voltLime
        : (plan.slug == 'pro'
            ? AppTheme.amber
            : Colors.white.withOpacity(0.3));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isRecommended
                ? AppTheme.voltLime.withOpacity(0.06)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: accent, width: isRecommended ? 1.5 : 1),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.label,
                    style: AppTheme.bigNum(22,
                        color: isCurrent
                            ? AppTheme.voltLime
                            : Colors.white),
                  ),
                  Row(children: [
                    Text(
                      plan.priceInr == 0
                          ? '₹0'
                          : '₹${plan.priceInr}',
                      style:
                          AppTheme.bigNum(22, color: accent),
                    ),
                    if (plan.priceInr > 0)
                      Text('/mo', style: AppTheme.label(12)),
                  ]),
                ]),
            const SizedBox(height: 12),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Icon(Icons.check_rounded,
                        color: accent, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(f,
                            style: AppTheme.label(13,
                                color: Colors.white))),
                  ]),
                )),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrent ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent
                      ? Colors.white.withOpacity(0.08)
                      : (isRecommended ? AppTheme.voltLime : accent),
                  foregroundColor:
                      isCurrent ? AppTheme.ink3 : AppTheme.bg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(
                  isCurrent
                      ? 'Current Plan'
                      : (plan.priceInr == 0
                          ? 'Stay Free'
                          : 'Start ${plan.label}'),
                  style: AppTheme.label(14).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? AppTheme.ink3 : AppTheme.bg,
                  ),
                ),
              ),
            ),
          ]),
        ),
        if (isRecommended)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.voltLime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Recommended',
                style: AppTheme.label(10, color: AppTheme.bg).copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}
