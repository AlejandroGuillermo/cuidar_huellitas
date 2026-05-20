import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int careReminderId = 1001;
  static const int _fallbackHour = 18;
  static const int _careMarginHours = 2;
  static const double _minRoutineConfidence = 0.3;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionsRequestedThisSession = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await init();

    var granted = true;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();
    if (androidGranted != null) {
      granted = granted && androidGranted;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) {
      granted = granted && iosGranted;
    }

    return granted;
  }

  Future<bool> requestPermissionsOncePerSession() async {
    if (_permissionsRequestedThisSession) {
      return true;
    }

    _permissionsRequestedThisSession = true;
    return requestPermissions();
  }

  Future<void> scheduleCareReminder(DateTime targetTime) async {
    await init();

    final scheduledTime = tz.TZDateTime.from(targetTime, tz.local);
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'care_reminders',
      'Recordatorios de cuidado',
      channelDescription: 'Avisos locales para volver a cuidar la mascota.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      careReminderId,
      'CuidAR Huellitas',
      'Tu mascota te espera',
      scheduledTime,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelCareReminder() async {
    await init();
    await _plugin.cancel(careReminderId);
  }

  Future<DateTime> nextCareReminderTargetForCurrentUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return _nextLocalTime(hour: _fallbackHour);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patrones_rutina')
          .where('id_usuario', isEqualTo: userId)
          .get();

      final patterns = snapshot.docs
          .map((doc) => doc.data())
          .where(
            (data) =>
                (data['confianza'] ?? 0).toDouble() >= _minRoutineConfidence,
          )
          .toList();

      if (patterns.isEmpty) {
        return _nextLocalTime(hour: _fallbackHour);
      }

      patterns.sort(
        (a, b) => (b['confianza'] ?? 0).toDouble().compareTo(
          (a['confianza'] ?? 0).toDouble(),
        ),
      );

      final hourAverage = (patterns.first['hora_promedio'] ?? _fallbackHour)
          .toDouble();
      final baseTime = _dateFromDecimalHour(hourAverage);
      return baseTime.add(const Duration(hours: _careMarginHours));
    } catch (error) {
      debugPrint('Error programando recordatorio: $error');
      return _nextLocalTime(hour: _fallbackHour);
    }
  }

  Future<void> rescheduleCareReminderForCurrentUser() async {
    final target = await nextCareReminderTargetForCurrentUser();
    await cancelCareReminder();
    await scheduleCareReminder(target);
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error) {
      debugPrint('No se pudo configurar timezone local: $error');
      tz.setLocalLocation(tz.UTC);
    }
  }

  DateTime _dateFromDecimalHour(double decimalHour) {
    final hour = decimalHour.floor().clamp(0, 23);
    final minute = ((decimalHour - hour) * 60).round().clamp(0, 59);
    return _nextLocalTime(hour: hour, minute: minute);
  }

  DateTime _nextLocalTime({required int hour, int minute = 0}) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }
}
