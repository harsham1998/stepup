import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/challenge.dart';

final activeChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final data = await ApiClient.instance.get('/challenges', {'status': 'active'}) as List;
  return data.map((j) => Challenge.fromJson(j as Map<String, dynamic>)).toList();
});

final challengeDetailProvider = FutureProvider.family<Challenge, String>((ref, id) async {
  final data = await ApiClient.instance.get('/challenges/$id') as Map<String, dynamic>;
  return Challenge.fromJson(data);
});
