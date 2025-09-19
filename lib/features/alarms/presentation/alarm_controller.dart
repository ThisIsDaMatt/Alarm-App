import 'package:flutter/foundation.dart';
import 'package:flutter_alarm_app/features/alarms/data/repositories/alarm_repository_prefs.dart';
import 'package:flutter_alarm_app/features/alarms/data/repositories/alarm_repository_hive.dart';
import 'package:flutter_alarm_app/features/alarms/domain/entities/alarm.dart';
import 'package:flutter_alarm_app/features/alarms/services/alarm_scheduler.dart';

class AlarmController extends ChangeNotifier {
  // Prefer Hive; fallback to SharedPreferences
  late final dynamic _repo; // AlarmRepositoryHive | AlarmRepositoryPrefs
  final AlarmScheduler _scheduler;

  AlarmController({AlarmRepositoryPrefs? repository, AlarmScheduler? scheduler})
      : _scheduler = scheduler ?? AlarmScheduler() {
    // Try Hive first
    try {
      _repo = AlarmRepositoryHive();
    } catch (_) {
      _repo = repository ?? AlarmRepositoryPrefs();
    }
  }

  List<Alarm> _alarms = [];
  List<Alarm> get alarms => List.unmodifiable(_alarms);

  Future<void> load() async {
    _alarms = await _repo.getAlarms();
    // Reschedule active alarms on load
    for (final a in _alarms) {
      if (a.isActive) {
        final t = _nextTrigger(a);
        _scheduler.scheduleAlarm(a.id, t);
      }
    }
    notifyListeners();
  }

  Future<void> addAlarm(DateTime time, {String? label}) async {
    final alarm = Alarm(id: UniqueKey().toString(), time: time, isActive: true, label: label);
    await _repo.createAlarm(alarm);
    _alarms = await _repo.getAlarms();
    _scheduler.scheduleAlarm(alarm.id, _nextTrigger(alarm));
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm updated) async {
    await _repo.updateAlarm(updated);
    _alarms = await _repo.getAlarms();
    if (updated.isActive) {
      _scheduler.scheduleAlarm(updated.id, _nextTrigger(updated));
    } else {
      _scheduler.cancelAlarm(updated.id);
    }
    notifyListeners();
  }

  Future<void> deleteAlarm(String id) async {
    await _repo.deleteAlarm(id);
    _alarms = await _repo.getAlarms();
    _scheduler.cancelAlarm(id);
    notifyListeners();
  }

  Future<void> snooze(String id) async {
    final idx = _alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final a = _alarms[idx];
    final snoozedTime = DateTime.now().add(Duration(minutes: a.snoozeMinutes));
    _scheduler.scheduleAlarm(a.id, snoozedTime);
  }

  Future<void> stop(String id) async {
    // If it's non-repeating, keep active state and just wait next day; if repeating, schedule next per pattern
    final idx = _alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final a = _alarms[idx];
    final next = _nextTrigger(a);
    _scheduler.scheduleAlarm(a.id, next);
  }

  DateTime _ensureFuture(DateTime t) {
    final now = DateTime.now();
    if (t.isAfter(now)) return t;
    // move to next day same time
    return t.add(const Duration(days: 1));
  }

  DateTime _nextTrigger(Alarm a) {
    // If Hive extension exists, use it; else fallback to simple ensureFuture
    try {
      // dynamic call to extension provided in hive repo file
      return (a as dynamic).nextTrigger(DateTime.now()) as DateTime;
    } catch (_) {
      return _ensureFuture(a.time);
    }
  }
}
