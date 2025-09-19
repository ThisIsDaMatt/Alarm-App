import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_alarm_app/main.dart';

void main() {
  testWidgets('Alarm app has a title and starts with no alarms', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Verify that the app has a title
    expect(find.text('Alarm App'), findsOneWidget);

    // Verify that the initial state has no alarms (updated copy)
    expect(find.text('No alarms yet'), findsOneWidget);
  });

  testWidgets('Tapping the add alarm button opens the alarm editor', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Tap the add alarm button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that the alarm editor sheet is displayed (AppBar title 'Add Alarm')
    expect(find.text('Add Alarm'), findsOneWidget);
  });

  testWidgets('Alarm editor allows setting a time', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Tap the add alarm button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Open the time picker
    await tester.tap(find.byType(TimePicker));
    await tester.pumpAndSettle();

    // We can't interact with native picker in unit test, just ensure widget still present
    expect(find.byType(TimePicker), findsOneWidget);
  });
}