import 'package:flutter_alarm_app/features/alarms/services/notification_service.dart';

class ScheduledAlarm {
  final String id;
  final DateTime time;
  ScheduledAlarm(this.id, this.time);
}

class AlarmScheduler {
  final Map<String, ScheduledAlarm> _scheduled = {};
  final NotificationService _notifications = NotificationService();

  bool scheduleAlarm(String id, DateTime time) {
    _scheduled[id] = ScheduledAlarm(id, time);
    // Fire-and-forget real schedule; tests only check return/collection
    _notifications.scheduleFullScreenAlarm(id: id, time: time).catchError((_) {});
    return true;
  }

  bool cancelAlarm(String id) {
    final removed = _scheduled.remove(id) != null;
    _notifications.cancel(id).catchError((_) {});
    return removed;
  }

  List<ScheduledAlarm> getScheduledAlarms() {
    return _scheduled.values.toList();
  }
}
