import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/subscription_plan.dart';

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final data = await ApiClient.instance.get('/subscriptions/plans') as List;
  return data.map((j) => SubscriptionPlan.fromJson(j as Map<String, dynamic>)).toList();
});

final mySubscriptionProvider = FutureProvider<UserSubscription>((ref) async {
  final data = await ApiClient.instance.get('/subscriptions/me') as Map<String, dynamic>;
  return UserSubscription.fromJson(data);
});
