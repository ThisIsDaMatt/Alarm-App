import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarm_app/features/settings/settings_service.dart';

class RingScreen extends StatefulWidget {
  final String? payload;
  const RingScreen({Key? key, this.payload}) : super(key: key);

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _controller;
  // Fallback assets in case dynamic manifest lookup finds none
  final List<String> _fallbackVoiceAssets = const [
    'assets/audio/voices/voice_1.mp3',
    'assets/audio/voices/voice_2.mp3',
    'assets/audio/voices/voice_3.mp3',
  ];
  static int? _lastIndex; // avoid immediate repeat

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _startPlayback();
  }

  Future<void> _startPlayback() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.alarm,
        ),
        androidWillPauseWhenDucked: false,
      ));
    } catch (_) {}
    // Pick a random voice line each time, honoring voice mode
    final settings = SettingsService();
    final avoidRepeat = await settings.getAvoidRepeat();
    final mode = await settings.getVoiceMode(); // 'aggressive' | 'motivational'
    final List<String> assets = await _resolveVoiceAssets(mode);
    if (assets.isEmpty) {
      // fallback to default list
      assets.addAll(_fallbackVoiceAssets);
    }
    int index = Random().nextInt(assets.isEmpty ? 1 : assets.length);
    if (avoidRepeat && _lastIndex != null && assets.length > 1) {
      if (index == _lastIndex) index = (index + 1) % assets.length;
    }
    _lastIndex = index;
    final asset = assets[index];
    try {
      await _player.setAsset(asset);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
    } catch (e) {
      // If assets are missing in dev, ignore to keep screen functional
    }
  }

  Future<List<String>> _resolveVoiceAssets(String mode) async {
    try {
      // Load Flutter's asset manifest and filter by our voice mode folder
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestJson) as Map<String, dynamic>;
      final prefix = 'assets/audio/voices/$mode/';
      final exts = ['.mp3', '.m4a', '.aac', '.wav', '.ogg'];
      final keys = manifest.keys.where((k) => k.startsWith(prefix) && exts.any((e) => k.toLowerCase().endsWith(e)));
      return keys.toList()..sort();
    } catch (_) {
      return <String>[];
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
                child: const Icon(Icons.alarm, size: 160, color: Colors.white),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Snooze alarm',
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop('snooze');
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: const StadiumBorder()),
                          child: const Text('Snooze'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Stop alarm',
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            Navigator.of(context).pop('stop');
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: const StadiumBorder()),
                          child: const Text('Stop'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
