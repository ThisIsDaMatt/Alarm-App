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
    try {
      tz.initializeTimeZones();
    } catch (_) {
      // ignore if already initialized
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        navigatorKey.currentState
            ?.pushNamed('/ring', arguments: response.payload)
            .then((result) {
          if (result is String) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'ALARM_CATEGORY',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('SNOOZE_ACTION', 'Snooze'),
              DarwinNotificationAction.destructive('STOP_ACTION', 'Stop'),
            ],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.customDismissAction,
            },
          ),
        ],
      );
                  controller.snooze(id);
                } else if (result == 'stop') {
                  controller.stop(id);
                }
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final id = response.payload;
          final actionId = response.actionId;
          if (actionId == 'SNOOZE_ACTION' || actionId == 'STOP_ACTION') {
            final ctx = navigatorKey.currentContext;
            if (ctx != null && id != null && id.isNotEmpty) {
              final controller = ctx.read<AlarmController>();
              if (actionId == 'SNOOZE_ACTION') {
                controller.snooze(id);
              } else {
                controller.stop(id);
              }
            }
            return;
          }
          navigatorKey.currentState?.pushNamed('/ring', arguments: id).then((result) {
            if (result is String && id != null && id.isNotEmpty) {
              final ctx = navigatorKey.currentContext;
              if (ctx != null) {
                final controller = ctx.read<AlarmController>();
                if (result == 'snooze') {
                  controller.snooze(id);
                } else if (result == 'stop') {
                  controller.stop(id);
                }
              }
            }
          });
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }
      // On iOS, explicitly request permissions for better UX
      await _plugin
          .resolvePlatformSpecificImplementation<DarwinFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true, badge: true);

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
      androidAllowWhileIdle: true,
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
