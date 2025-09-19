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

    // Fill in the alarm details.
    await tester.enterText(find.byKey(Key('timeField')), '07:00 AM');
    await tester.tap(find.byKey(Key('saveButton')));
    await tester.pumpAndSettle();

    // Verify that the alarm is added to the alarms list.
    expect(find.text('07:00 AM'), findsOneWidget);

    // Tap on the alarm to edit it.
    await tester.tap(find.text('07:00 AM'));
    await tester.pumpAndSettle();

    // Verify that the alarm editor page is displayed again.
    expect(find.text('Edit Alarm'), findsOneWidget);

    // Change the alarm time.
    await tester.enterText(find.byKey(Key('timeField')), '08:00 AM');
    await tester.tap(find.byKey(Key('saveButton')));
    await tester.pumpAndSettle();

    // Verify that the alarm time is updated in the list.
    expect(find.text('08:00 AM'), findsOneWidget);
    expect(find.text('07:00 AM'), findsNothing);
  });
}