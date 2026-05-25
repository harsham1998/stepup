import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/reward.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

final rewardsProvider = FutureProvider.family<List<Reward>, String>((ref, category) async {
  final params = category == 'all' ? null : {'category': category};
  final data = await ApiClient.instance.get('/rewards', params) as List;
  return data.map((j) => Reward.fromJson(j as Map<String, dynamic>)).toList();
});
