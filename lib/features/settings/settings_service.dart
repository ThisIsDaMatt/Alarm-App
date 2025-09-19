import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kVoiceMode = 'voice_mode'; // 'aggressive' | 'motivational'
  static const _kAvoidRepeat = 'avoid_repeat';
  static const _kDefaultSnooze = 'default_snooze_minutes'; // int
  static const _kDefaultVolume = 'default_volume'; // double 0..1

  Future<String> getVoiceMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kVoiceMode) ?? 'aggressive';
  }

  Future<void> setVoiceMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVoiceMode, mode);
  }

  Future<bool> getAvoidRepeat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAvoidRepeat) ?? true;
  }

  Future<void> setAvoidRepeat(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAvoidRepeat, v);
  }

  Future<int> getDefaultSnoozeMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDefaultSnooze) ?? 10;
  }

  Future<void> setDefaultSnoozeMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDefaultSnooze, minutes);
  }

  Future<double> getDefaultVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kDefaultVolume) ?? 1.0;
  }

  Future<void> setDefaultVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDefaultVolume, volume.clamp(0.0, 1.0));
  }
}
