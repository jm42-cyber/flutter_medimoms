import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_services_pro/main.dart';

void main() {
  testWidgets('App loads and renders without errors',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Wait for all async widgets to finish building
    await tester.pumpAndSettle();

    // ✅ Check if the app’s main title or any widget exists
    expect(find.byType(MaterialApp), findsOneWidget);

    // If you have a login screen or home screen, test for an identifying widget/text
    // Example (optional):
    // expect(find.text('Login'), findsOneWidget);
    // or expect(find.text('Midwife System'), findsOneWidget);

    // Print a success log
    debugPrint('✅ Widget test ran successfully.');
  });
}
