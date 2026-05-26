import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/xp_level.dart';

final xpLevelProvider = FutureProvider<XpLevel>((ref) async {
  final data = await ApiClient.instance.get('/xp') as Map<String, dynamic>;
  return XpLevel.fromJson(data);
});
