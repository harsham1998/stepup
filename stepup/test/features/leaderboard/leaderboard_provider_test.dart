import 'package:flutter_test/flutter_test.dart';
import 'package:stepup/features/leaderboard/providers/leaderboard_provider.dart';

void main() {
  test('globalLeaderboardProvider is defined', () {
    expect(globalLeaderboardProvider, isNotNull);
  });

  test('friendsLeaderboardProvider is defined', () {
    expect(friendsLeaderboardProvider, isNotNull);
  });

  test('cityLeaderboardProvider is defined', () {
    expect(cityLeaderboardProvider, isNotNull);
  });
}
