import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/mission.dart';

final dailyMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  final data = await ApiClient.instance.get('/missions/daily') as List;
  return data.map((j) => Mission.fromJson(j as Map<String, dynamic>)).toList();
});

final weeklyMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  final data = await ApiClient.instance.get('/missions/weekly') as List;
  return data.map((j) => Mission.fromJson(j as Map<String, dynamic>)).toList();
});

final seasonalMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  final data = await ApiClient.instance.get('/missions/seasonal') as List;
  return data.map((j) => Mission.fromJson(j as Map<String, dynamic>)).toList();
});
