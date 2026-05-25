import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/battle_pass.dart';

final battlePassProvider = FutureProvider<BattlePassProgress?>((ref) async {
  final data = await ApiClient.instance.get('/battlepass/current') as Map<String, dynamic>;
  if (data['active'] == false) return null;
  return BattlePassProgress.fromJson(data);
});
