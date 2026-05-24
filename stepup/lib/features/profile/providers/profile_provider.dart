import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final data = await ApiClient.instance.get('/auth/profile') as Map<String, dynamic>;
    return data;
  } catch (_) {
    return {};
  }
});
