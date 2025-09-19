import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_alarm_app/features/alarms/domain/entities/alarm.dart';
import 'package:flutter_alarm_app/features/alarms/data/repositories/alarm_repository_hive.dart';

void main() {
  group('AlarmNextTrigger extension', () {
    test('no repeat schedules next day if past', () {
      final now = DateTime(2025, 1, 1, 8, 0); // Wed
      final alarm = Alarm(id: 'a', time: DateTime(2025, 1, 1, 7, 30), isActive: true);
      final next = alarm.nextTrigger(now);
      expect(next, DateTime(2025, 1, 2, 7, 30));
    });

    test('no repeat schedules today if future', () {
      final now = DateTime(2025, 1, 1, 6, 0);
      final alarm = Alarm(id: 'a', time: DateTime(2025, 1, 1, 7, 30), isActive: true);
      final next = alarm.nextTrigger(now);
      expect(next, DateTime(2025, 1, 1, 7, 30));
    });

    test('weekdays mask chooses next weekday', () {
      // Mask for Mon-Fri => bits 1..5 set (Sun=0..Sat=6). Here using 0b0111110 = 0x3E = 62
      const weekdaysMask = 0x3E;
      final now = DateTime(2025, 1, 3, 10, 0); // Fri 10:00
      final alarm = Alarm(id: 'a', time: DateTime(2025, 1, 3, 9, 0), isActive: true, repeatDays: weekdaysMask);
      final next = alarm.nextTrigger(now);
      // Next should be Mon 2025-01-06 09:00
      expect(next, DateTime(2025, 1, 6, 9, 0));
    });

    test('weekends mask chooses next weekend day', () {
      // Weekends Sat(6) + Sun(0) => (1<<6) | (1<<0) = 0b1000001 = 65
      const weekendMask = 65;
      final now = DateTime(2025, 1, 3, 8, 0); // Fri
      final alarm = Alarm(id: 'a', time: DateTime(2025, 1, 3, 9, 0), isActive: true, repeatDays: weekendMask);
      final next = alarm.nextTrigger(now);
      // Next should be Sat 2025-01-04 09:00
      expect(next, DateTime(2025, 1, 4, 9, 0));
    });
  });
}
