import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_alarm_app/features/alarms/services/alarm_scheduler.dart';

void main() {
  group('AlarmScheduler', () {
    late AlarmScheduler alarmScheduler;

    setUp(() {
      alarmScheduler = AlarmScheduler();
    });

    test('should schedule an alarm correctly', () {
      // Arrange
      final DateTime alarmTime = DateTime.now().add(Duration(minutes: 1));
      final String alarmId = 'test_alarm';

      // Act
      final result = alarmScheduler.scheduleAlarm(alarmId, alarmTime);

      // Assert
      expect(result, isTrue);
      // Additional checks can be added here to verify the alarm was scheduled
    });

    test('should cancel an alarm correctly', () {
      // Arrange
      final String alarmId = 'test_alarm';
      alarmScheduler.scheduleAlarm(alarmId, DateTime.now().add(Duration(minutes: 1)));

      // Act
      final result = alarmScheduler.cancelAlarm(alarmId);

      // Assert
      expect(result, isTrue);
      // Additional checks can be added here to verify the alarm was canceled
    });

    test('should return a list of scheduled alarms', () {
      // Arrange
      final String alarmId1 = 'test_alarm_1';
      final String alarmId2 = 'test_alarm_2';
      alarmScheduler.scheduleAlarm(alarmId1, DateTime.now().add(Duration(minutes: 1)));
      alarmScheduler.scheduleAlarm(alarmId2, DateTime.now().add(Duration(minutes: 2)));

      // Act
      final alarms = alarmScheduler.getScheduledAlarms();

      // Assert
      expect(alarms.length, 2);
      expect(alarms.map((alarm) => alarm.id), containsAll([alarmId1, alarmId2]));
    });
  });
}