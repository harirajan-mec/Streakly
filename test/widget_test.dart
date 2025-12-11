// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:Streakly/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StreaklyApp());

    // Let initial microtasks run and verify splash renders
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Streakly'), findsOneWidget);

    // Advance time to allow splash timers to complete so no pending timers remain
    await tester.pump(const Duration(seconds: 6));
  });
}
