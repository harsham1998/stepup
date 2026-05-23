import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

final walletBalanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiClient.instance.get('/wallet/balance') as Map<String, dynamic>;
});

final walletTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.instance.get('/wallet/transactions') as List;
});
