import 'dart:collection';

import 'package:flutter_alarm_app/features/alarms/domain/entities/alarm.dart';

class AlarmRepositoryImpl {
  final Map<String, Alarm> _store = {};

  Future<void> createAlarm(Alarm alarm) async {
    _store[alarm.id] = alarm;
  }

  Future<void> deleteAlarm(String id) async {
    _store.remove(id);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    if (_store.containsKey(alarm.id)) {
      _store[alarm.id] = alarm;
    }
  }

  Future<List<Alarm>> getAlarms() async {
    return UnmodifiableListView(_store.values.toList());
  }
}
