import 'package:flutter/foundation.dart';

@immutable
class Alarm {
  final String id;
  final DateTime time;
  final bool isActive;
  final String? label;
  // Bitmask 0bSMTWTFS for days (Sun=0..Sat=6) or list alternative
  final int repeatDays; // 0 = no repeat
  final int snoozeMinutes; // default 10
  final double volume; // 0.0..1.0
  final bool vibration;

  const Alarm({
    required this.id,
    required this.time,
    required this.isActive,
    this.label,
    this.repeatDays = 0,
    this.snoozeMinutes = 10,
    this.volume = 1.0,
    this.vibration = true,
  });

  Alarm copyWith({
    String? id,
    DateTime? time,
    bool? isActive,
    String? label,
    int? repeatDays,
    int? snoozeMinutes,
    double? volume,
    bool? vibration,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      volume: volume ?? this.volume,
      vibration: vibration ?? this.vibration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alarm &&
        other.id == id &&
        other.time == time &&
        other.isActive == isActive &&
        other.label == label &&
        other.repeatDays == repeatDays &&
        other.snoozeMinutes == snoozeMinutes &&
        other.volume == volume &&
        other.vibration == vibration;
  }

  @override
  int get hashCode => Object.hash(id, time, isActive, label, repeatDays, snoozeMinutes, volume, vibration);

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'isActive': isActive,
        'label': label,
        'repeatDays': repeatDays,
        'snoozeMinutes': snoozeMinutes,
        'volume': volume,
        'vibration': vibration,
      };

  static Alarm fromJson(Map<String, dynamic> m) => Alarm(
        id: m['id'] as String,
        time: DateTime.parse(m['time'] as String),
        isActive: m['isActive'] as bool? ?? true,
        label: m['label'] as String?,
        repeatDays: m['repeatDays'] as int? ?? 0,
        snoozeMinutes: m['snoozeMinutes'] as int? ?? 10,
        volume: (m['volume'] as num?)?.toDouble() ?? 1.0,
        vibration: m['vibration'] as bool? ?? true,
      );
}
