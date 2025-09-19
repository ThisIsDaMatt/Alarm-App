import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_alarm_app/features/alarms/presentation/alarm_controller.dart';
import 'package:flutter_alarm_app/features/alarms/domain/entities/alarm.dart';

class FakeScheduler implements AlarmSchedulerLike {
  final List<Map<String, dynamic>> calls = [];
  @override
  bool cancelAlarm(String id) {
    calls.add({'op': 'cancel', 'id': id});
    return true;
  }

  @override
  List<dynamic> getScheduledAlarms() => [];

  @override
  bool scheduleAlarm(String id, DateTime time) {
    calls.add({'op': 'schedule', 'id': id, 'time': time});
    return true;
  }
}

// Add a minimal interface to ease testing without changing production classes
abstract class AlarmSchedulerLike {
  bool scheduleAlarm(String id, DateTime time);
  bool cancelAlarm(String id);
  List<dynamic> getScheduledAlarms();
}

void main() {
  test('snooze schedules alarm in +snooze minutes', () async {
    final fake = FakeScheduler();
    final c = AlarmController(scheduler: fake as dynamic);
    final now = DateTime(2025, 1, 1, 7, 0);
    final a = Alarm(id: 'x', time: now, isActive: true, snoozeMinutes: 5);
    c.._alarms = [a];
    await c.snooze('x');
    expect(fake.calls.where((e) => e['op'] == 'schedule').length, 1);
  });

  test('stop schedules next trigger', () async {
    final fake = FakeScheduler();
    final c = AlarmController(scheduler: fake as dynamic);
    final now = DateTime(2025, 1, 1, 7, 0);
    final a = Alarm(id: 'y', time: now, isActive: true);
    c.._alarms = [a];
    await c.stop('y');
    expect(fake.calls.where((e) => e['op'] == 'schedule').isNotEmpty, true);
  });
}
