import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_alarm_app/main.dart';

void main() {
  testWidgets('App flow test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the initial screen is the alarms page.
    expect(find.text('Alarms'), findsOneWidget);

    // Tap on the add alarm button.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that the alarm editor page is displayed.
    expect(find.text('Add Alarm'), findsOneWidget);

  // Fill in the label (the time field key is actually label input)
  await tester.enterText(find.byKey(Key('timeField')), 'Morning alarm');
  await tester.tap(find.byKey(Key('saveButton')));
    await tester.pumpAndSettle();

  // Verify that the alarm is added to the alarms list (time is formatted dynamically)
  expect(find.textContaining('AM').evaluate().isNotEmpty || find.textContaining('PM').evaluate().isNotEmpty, true);

  // Tap on the first alarm card to edit it.
  await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    // Verify that the alarm editor page is displayed again.
    expect(find.text('Edit Alarm'), findsOneWidget);

    // Change the label.
    await tester.enterText(find.byKey(Key('timeField')), 'Updated alarm');
    await tester.tap(find.byKey(Key('saveButton')));
    await tester.pumpAndSettle();

    // Verify that the updated label appears
    expect(find.text('Updated alarm'), findsOneWidget);
  });
}