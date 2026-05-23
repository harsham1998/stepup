import 'package:flutter_test/flutter_test.dart';
import 'package:stepup/features/auth/providers/auth_provider.dart';

void main() {
  test('authServiceProvider is defined', () {
    expect(authServiceProvider, isNotNull);
  });

  test('isLoggedInProvider is defined', () {
    expect(isLoggedInProvider, isNotNull);
  });
}
