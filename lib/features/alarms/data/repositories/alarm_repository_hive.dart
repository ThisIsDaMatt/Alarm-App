import 'package:hive/hive.dart';
import 'package:flutter_alarm_app/features/alarms/domain/entities/alarm.dart';

class AlarmRepositoryHive {
  static const String boxName = 'alarms_box_v1';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(101)) {
      Hive.registerAdapter(AlarmAdapter());
    }
    await Hive.openBox<Alarm>(boxName);
  }

  Box<Alarm> get _box => Hive.box<Alarm>(boxName);

  Future<List<Alarm>> getAlarms() async {
    return _box.values.toList(growable: false);
  }

  Future<void> createAlarm(Alarm alarm) async {
    await _box.put(alarm.id, alarm);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _box.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(String id) async {
    await _box.delete(id);
  }
}

class AlarmAdapter extends TypeAdapter<Alarm> {
  @override
  final int typeId = 101;

  @override
  Alarm read(BinaryReader reader) {
    final id = reader.readString();
    final timeMillis = reader.readInt();
    final isActive = reader.readBool();
    final label = reader.read();
    final repeatDays = reader.readInt();
    final snooze = reader.readInt();
    final volume = reader.readDouble();
    final vibration = reader.readBool();
    return Alarm(
      id: id,
      time: DateTime.fromMillisecondsSinceEpoch(timeMillis),
      isActive: isActive,
      label: label as String?,
      repeatDays: repeatDays,
      snoozeMinutes: snooze,
      volume: volume,
      vibration: vibration,
    );
  }

  @override
  void write(BinaryWriter writer, Alarm obj) {
    writer
      ..writeString(obj.id)
      ..writeInt(obj.time.millisecondsSinceEpoch)
      ..writeBool(obj.isActive)
      ..write(obj.label)
      ..writeInt(obj.repeatDays)
      ..writeInt(obj.snoozeMinutes)
      ..writeDouble(obj.volume)
      ..writeBool(obj.vibration);
  }
}

extension AlarmNextTrigger on Alarm {
  // Compute next trigger considering repeatDays bitmask; if 0, next same time >= now (tomorrow si ya pasó)
  DateTime nextTrigger(DateTime now) {
    final base = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (repeatDays == 0) {
      if (base.isAfter(now)) return base;
      return base.add(const Duration(days: 1));
    }
    // Find next day among repeat days
    for (int i = 0; i < 7; i++) {
      final candidate = base.add(Duration(days: i));
      final weekday = candidate.weekday % 7; // Mon=1..Sun=7 => Sun=0
      final bit = 1 << weekday;
      if ((repeatDays & bit) != 0 && candidate.isAfter(now)) {
        return candidate;
      }
    }
    // Fallback next week same day/time
    return base.add(const Duration(days: 7));
  }
}
