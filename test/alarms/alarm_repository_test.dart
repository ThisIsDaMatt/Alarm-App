import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_alarm_app/features/alarms/data/repositories/alarm_repository_impl.dart';
import 'package:flutter_alarm_app/features/alarms/domain/entities/alarm.dart';

void main() {
  late AlarmRepositoryImpl alarmRepository;

  setUp(() {
    alarmRepository = AlarmRepositoryImpl();
  });

  group('AlarmRepository Tests', () {
    test('should create an alarm', () async {
      final alarm = Alarm(id: '1', time: DateTime.now(), isActive: true);
      await alarmRepository.createAlarm(alarm);
      final alarms = await alarmRepository.getAlarms();
      expect(alarms, contains(alarm));
    });

    test('should delete an alarm', () async {
      final alarm = Alarm(id: '2', time: DateTime.now(), isActive: true);
      await alarmRepository.createAlarm(alarm);
      await alarmRepository.deleteAlarm(alarm.id);
      final alarms = await alarmRepository.getAlarms();
      expect(alarms, isNot(contains(alarm)));
    });

    test('should update an alarm', () async {
      final alarm = Alarm(id: '3', time: DateTime.now(), isActive: true);
      await alarmRepository.createAlarm(alarm);
      final updatedAlarm = alarm.copyWith(isActive: false);
      await alarmRepository.updateAlarm(updatedAlarm);
      final alarms = await alarmRepository.getAlarms();
      expect(alarms.firstWhere((a) => a.id == alarm.id).isActive, isFalse);
    });

    test('should retrieve alarms', () async {
      final alarm1 = Alarm(id: '4', time: DateTime.now(), isActive: true);
      final alarm2 = Alarm(id: '5', time: DateTime.now().add(Duration(hours: 1)), isActive: true);
      await alarmRepository.createAlarm(alarm1);
      await alarmRepository.createAlarm(alarm2);
      final alarms = await alarmRepository.getAlarms();
      expect(alarms.length, 2);
      expect(alarms, containsAll([alarm1, alarm2]));
    });
  });
}