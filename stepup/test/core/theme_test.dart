import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepup/core/theme.dart';

void main() {
  test('dark theme has correct background color', () {
    expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF0C0C18));
  });

  test('dark theme primary color is indigo', () {
    expect(AppTheme.dark.colorScheme.primary, const Color(0xFF6366F1));
  });
}
