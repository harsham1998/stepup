// stepup/lib/features/profile/providers/reputation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/reputation.dart';

final reputationProvider = FutureProvider<Reputation>((ref) async {
  final data = await ApiClient.instance.get('/reputation') as Map<String, dynamic>;
  return Reputation.fromJson(data);
});
