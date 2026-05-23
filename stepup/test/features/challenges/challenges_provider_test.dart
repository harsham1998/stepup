import 'package:flutter_test/flutter_test.dart';
import 'package:stepup/features/challenges/providers/challenges_provider.dart';

void main() {
  test('activeChallengesProvider is defined', () {
    expect(activeChallengesProvider, isNotNull);
  });

  test('challengeDetailProvider is defined', () {
    expect(challengeDetailProvider, isNotNull);
  });
}
