class SubscriptionPlan {
  final String slug, label;
  final int priceInr, sortOrder;
  final List<String> features;
  const SubscriptionPlan({required this.slug, required this.label, required this.priceInr, required this.sortOrder, required this.features});
  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
    slug: j['slug'] as String, label: j['label'] as String,
    priceInr: (j['price_inr'] as num).toInt(), sortOrder: (j['sort_order'] as num? ?? 0).toInt(),
    features: (j['features'] as List? ?? []).map((e) => e.toString()).toList(),
  );
}

class UserSubscription {
  final String planSlug, status;
  const UserSubscription({required this.planSlug, required this.status});
  factory UserSubscription.fromJson(Map<String, dynamic> j) => UserSubscription(
    planSlug: j['plan_slug'] as String? ?? 'free', status: j['status'] as String? ?? 'active',
  );
  bool get isPro => planSlug == 'pro';
  bool get isPaid => planSlug != 'free';
}
