import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/rival.dart';

final rivalsProvider = FutureProvider<List<Rival>>((ref) async {
  final data = await ApiClient.instance.get('/rivals') as List;
  return data.map((j) => Rival.fromJson(j as Map<String, dynamic>)).toList();
});

final battlesProvider = FutureProvider<List<Battle>>((ref) async {
  final data = await ApiClient.instance.get('/rivals/battles') as List;
  return data.map((j) => Battle.fromJson(j as Map<String, dynamic>)).toList();
});
