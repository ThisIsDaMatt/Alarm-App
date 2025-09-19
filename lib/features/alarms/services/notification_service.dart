import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'package:flutter_alarm_app/features/alarms/presentation/alarm_controller.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Time zones (safe to call more than once)
    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: <DarwinNotificationCategory>[
        const DarwinNotificationCategory(
          'ALARM_CATEGORY',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction(
              'SNOOZE_ACTION',
              'Snooze',
            ),
            DarwinNotificationAction(
              'STOP_ACTION',
              'Stop',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.customDismissAction,
          },
        ),
      ],
    );

  final initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? id = response.payload;
        final String? actionId = response.actionId;

        // Handle iOS/Android action buttons
        if (actionId == 'SNOOZE_ACTION' || actionId == 'STOP_ACTION') {
          final ctx = navigatorKey.currentContext;
          if (ctx != null && id != null && id.isNotEmpty) {
            final controller = ctx.read<AlarmController>();
            if (actionId == 'SNOOZE_ACTION') {
              await controller.snooze(id);
            } else {
              await controller.stop(id);
            }
          }
          return;
        }

        // Default: open ring UI and handle result
        navigatorKey.currentState?.pushNamed('/ring', arguments: id).then((result) async {
          if (result is String && id != null && id.isNotEmpty) {
            final ctx = navigatorKey.currentContext;
            if (ctx != null) {
              final controller = ctx.read<AlarmController>();
              if (result == 'snooze') {
                await controller.snooze(id);
              } else if (result == 'stop') {
                await controller.stop(id);
              }
            }
          }
        });
      },
    );

    // Ensure Android notification channel exists with max importance
    const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarms',
      description: 'Alarm notifications with full-screen intent',
      importance: Importance.max,
      playSound: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // iOS permissions (Android handled via manifest and runtime)
  await _plugin
    .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
    ?.requestPermissions(alert: true, sound: true, badge: true);
  }

  Future<void> scheduleFullScreenAlarm({
    required String id,
    required DateTime time,
    String title = 'Alarm',
    String body = 'Time to wake up',
    String? payload,
  }) async {
    final int notifId = _stableId(id);

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Alarm notifications with full-screen intent',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: false,
      ongoing: true,
      playSound: false,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
      categoryIdentifier: 'ALARM_CATEGORY',
    );

    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload ?? id,
    );
  }

  Future<void> cancel(String id) async {
    await _plugin.cancel(_stableId(id));
  }

  int _stableId(String id) {
    // Stable positive int from string
    return id.hashCode & 0x7fffffff;
  }
}
