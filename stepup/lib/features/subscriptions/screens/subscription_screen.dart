import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/subscription_provider.dart';
import '../../../shared/models/subscription_plan.dart';
import '../../../core/theme.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _yearly = false;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final mySubAsync = ref.watch(mySubscriptionProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: plansAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (_, __) => _SubBody(
            yearly: _yearly,
            onToggleBilling: (v) => setState(() => _yearly = v),
            plans: const [],
            currentPlan: null,
          ),
          data: (plans) => _SubBody(
            yearly: _yearly,
            onToggleBilling: (v) => setState(() => _yearly = v),
            plans: plans,
            currentPlan: mySubAsync.value?.planSlug,
          ),
        ),
      ),
    );
  }
}

class _SubBody extends StatelessWidget {
  final bool yearly;
  final ValueChanged<bool> onToggleBilling;
  final List<SubscriptionPlan> plans;
  final String? currentPlan;
  const _SubBody({
    required this.yearly,
    required this.onToggleBilling,
    required this.plans,
    required this.currentPlan,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text('Plans', style: AppTheme.label(13, color: AppTheme.ink2)),
        ]),
        const SizedBox(height: 16),
        Text('Choose a plan', style: AppTheme.bigNum(28)),
        const SizedBox(height: 4),
        Text('Consistency rewards · cancel anytime',
            style: AppTheme.label(13, color: AppTheme.ink2)),
        const SizedBox(height: 12),

        // Billing toggle
        Row(children: [
          GestureDetector(
            onTap: () => onToggleBilling(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: !yearly ? AppTheme.voltLime : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: !yearly ? AppTheme.voltLime : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text('Monthly',
                  style: AppTheme.label(12).copyWith(
                    color: !yearly ? AppTheme.bg : AppTheme.ink2,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onToggleBilling(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: yearly ? AppTheme.voltLime : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: yearly ? AppTheme.voltLime : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text('Yearly (save 20%)',
                  style: AppTheme.label(12).copyWith(
                    color: yearly ? AppTheme.bg : AppTheme.ink2,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Plan cards — use live data if available, else mock
        if (plans.isNotEmpty)
          ...plans.map((p) => _PlanCard(
                label: p.label,
                price: yearly ? (p.priceInr * 0.8).round() : p.priceInr,
                desc: p.priceInr == 0 ? 'Forever' : 'Consistency rewards',
                features: p.features,
                isCurrent: currentPlan == p.slug,
                isRecommended: p.slug == 'beginner',
                isComingSoon: p.slug == 'pro',
              ))
        else ...[
          _PlanCard(
            label: 'Free',
            price: 0,
            desc: 'Forever',
            features: const [
              '✓ Track all activities',
              '✓ Free challenges',
              '✗ No coin rewards',
            ],
            isCurrent: currentPlan == null || currentPlan == 'free',
            isRecommended: false,
            isComingSoon: false,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            label: 'Beginner',
            price: yearly ? 119 : 149,
            desc: 'Consistency rewards',
            features: const [
              '✓ 2 Paid challenges / month',
              '✓ Earn coins for consistency',
              '✓ Top 50% bonus',
              '✓ Gift card redemption',
            ],
            isCurrent: currentPlan == 'beginner',
            isRecommended: true,
            isComingSoon: false,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            label: 'Pro',
            price: yearly ? 239 : 299,
            desc: 'Unlimited · coming soon',
            features: const [],
            isCurrent: currentPlan == 'pro',
            isRecommended: false,
            isComingSoon: true,
          ),
        ],

        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                'Start Beginner — ₹${yearly ? 119 : 149}/mo',
                style: AppTheme.label(14, color: AppTheme.amber)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label, desc;
  final int price;
  final List<String> features;
  final bool isCurrent, isRecommended, isComingSoon;
  const _PlanCard({
    required this.label,
    required this.price,
    required this.desc,
    required this.features,
    required this.isCurrent,
    required this.isRecommended,
    required this.isComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRecommended
                ? AppTheme.voltLime.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRecommended
                  ? AppTheme.voltLime.withValues(alpha: 0.5)
                  : AppTheme.border,
              style: isComingSoon ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTheme.bigNum(22)),
                Row(children: [
                  Text(price == 0 ? '₹0' : '₹$price',
                      style: AppTheme.bigNum(22,
                          color: isRecommended ? AppTheme.voltLime : Colors.white)),
                  if (price > 0)
                    Text('/Mo', style: AppTheme.label(12, color: AppTheme.ink2)),
                ]),
              ],
            ),
            const SizedBox(height: 2),
            Text(desc, style: AppTheme.label(12, color: AppTheme.ink2)),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(f,
                        style: AppTheme.label(12,
                            color: f.startsWith('✗') ? AppTheme.ink3 : Colors.white)),
                  )),
            ],
            if (isCurrent) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text('Current plan',
                    style: AppTheme.label(11, color: AppTheme.ink2)),
              ),
            ],
          ]),
        ),
        if (isRecommended)
          Positioned(
            top: -10,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.voltLime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('★ Recommended',
                  style: AppTheme.label(9, color: AppTheme.bg)
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}
