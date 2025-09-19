import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_alarm_app/main.dart';

void main() {
  testWidgets('Alarm app has a title and starts with no alarms', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Verify that the app has a title
    expect(find.text('Alarm App'), findsOneWidget);

    // Verify that the initial state has no alarms
    expect(find.text('No alarms set'), findsOneWidget);
  });

  testWidgets('Tapping the add alarm button opens the alarm editor', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Tap the add alarm button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that the alarm editor page is displayed
    expect(find.text('Add Alarm'), findsOneWidget);
  });

  testWidgets('Alarm editor allows setting a time', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Tap the add alarm button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Set a time for the alarm
    await tester.tap(find.byType(TimePicker));
    await tester.pumpAndSettle();

    // Verify that the time picker is displayed
    expect(find.byType(TimePicker), findsOneWidget);
  });
}