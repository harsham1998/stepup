import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepup/shared/widgets/step_ring_widget.dart';

void main() {
  testWidgets('StepRingWidget shows correct percentage', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StepRingWidget(currentSteps: 5000, goalSteps: 10000)),
    ));
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('StepRingWidget shows 100% when at goal', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StepRingWidget(currentSteps: 15000, goalSteps: 15000)),
    ));
    expect(find.text('100%'), findsOneWidget);
  });
}
