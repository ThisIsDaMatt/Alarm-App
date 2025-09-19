# Flutter Alarm App

A modern Flutter alarm app (Android + iOS) that wakes you up with randomized voice lines.

## Features
- Create, edit, enable/disable alarms with repeat days, snooze, volume, vibration.
- Randomized voice playback on ring (avoid immediate repeats, configurable in Settings).
- Full-screen ringing UI with animations and big Snooze/Stop actions.
- Local notifications with proper channels (Android) and iOS categories/actions.
- Persistence via Hive; auto-reschedule on app start and after device reboot (Android).

## Requirements
- Flutter 3.x
- Android 8+ (tested), iOS 13+

## Permissions
- Android: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` (12+), `USE_FULL_SCREEN_INTENT`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK`.
- iOS: Alerts, Sounds, Badges. The app requests permissions on first run and sets an `ALARM_CATEGORY` with Snooze/Stop actions.

## Voice modes and assets
The app supports voice modes via Settings: `Aggressive` and `Motivational`.

Place your audio files under these folders:

```
assets/audio/voices/
   aggressive/
      line_1.mp3
      line_2.mp3
   motivational/
      line_1.mp3
      line_2.mp3
```

Notes:
- The app dynamically scans `AssetManifest.json` at runtime and plays a random file from the selected mode folder.
- Supported extensions: `.mp3`, `.m4a`, `.aac`, `.wav`, `.ogg`.
- If a mode folder is empty or missing, it falls back to the default files listed under `assets/audio/voices/`.

Ensure you declare the base folder in `pubspec.yaml`:

```
flutter:
   assets:
      - assets/audio/voices/
```

## Run
```
flutter pub get
flutter run
```

## Quick test
- Add an alarm 1–2 minutes ahead.
- When it rings, choose Snooze (re-schedules +N minutes) or Stop (schedules next occurrence, respecting repeat days).

## Notes
- On Android, after reboot the app is launched silently to rehydrate and reschedule alarms.
- For stricter background guarantees, consider adding a ForegroundService/WorkManager integration.
- On iOS, full-screen alarm behavior differs; the app uses high-priority notifications and navigates to the ring screen.

## Roadmap
- Foreground service (Android) for robust background re-scheduling.
- Better animations (hero between card and editor, microinteractions).
- Unit/integration tests for repository and scheduler.