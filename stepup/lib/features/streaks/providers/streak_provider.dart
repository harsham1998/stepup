import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/streak_status.dart';

final streakStatusProvider = FutureProvider<StreakStatus>((ref) async {
  final data = await ApiClient.instance.get('/streaks/status') as Map<String, dynamic>;
  return StreakStatus.fromJson(data);
});
