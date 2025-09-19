import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kVoiceMode = 'voice_mode'; // 'aggressive' | 'motivational'
  static const _kAvoidRepeat = 'avoid_repeat';

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
}
