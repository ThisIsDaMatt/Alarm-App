import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_alarm_app/features/alarms/domain/entities/alarm.dart';

class AlarmRepositoryPrefs {
  static const _kKey = 'alarms_v1';

  Future<List<Alarm>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    final List list = jsonDecode(raw) as List;
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createAlarm(Alarm alarm) async {
    final all = await getAlarms();
    all.add(alarm);
    await _save(all);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final all = await getAlarms();
    final idx = all.indexWhere((a) => a.id == alarm.id);
    if (idx != -1) {
      all[idx] = alarm;
      await _save(all);
    }
  }

  Future<void> deleteAlarm(String id) async {
    final all = await getAlarms();
    all.removeWhere((a) => a.id == id);
    await _save(all);
  }

  Future<void> _save(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(alarms.map(_toJson).toList());
    await prefs.setString(_kKey, encoded);
  }

  Map<String, dynamic> _toJson(Alarm a) => {
        'id': a.id,
        'time': a.time.toIso8601String(),
        'isActive': a.isActive,
        'label': a.label,
      };

  Alarm _fromJson(Map<String, dynamic> m) {
    return Alarm(
      id: m['id'] as String,
      time: DateTime.parse(m['time'] as String),
      isActive: m['isActive'] as bool? ?? true,
      label: m['label'] as String?,
    );
  }
}
