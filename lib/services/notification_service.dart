import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Workmanager is mobile-only; web stub keeps chrome builds clean.
import '_workmanager_io.dart'
    if (dart.library.html) '_workmanager_web.dart';

final _localNotifs = FlutterLocalNotificationsPlugin();

const _kAndroidNotifDetails = AndroidNotificationDetails(
  'ancora_reminders',
  'Medication Reminders',
  importance: Importance.high,
  priority: Priority.high,
);
const _kNotifDetails = NotificationDetails(android: _kAndroidNotifDetails);

class NotificationService {
  static Future<void> init() async {
    tz_data.initializeTimeZones();

    if (!kIsWeb) {
      await _localNotifs
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'ancora_reminders',
              'Medication Reminders',
              importance: Importance.high,
            ),
          );

      await _localNotifs.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      await initWorkmanager();
    }

    try {
      await _initFcm();
    } catch (e) {
      debugPrint('FCM init skipped: $e');
    }
  }

  static Future<void> _initFcm() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
        alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) await _storeToken(token);
    messaging.onTokenRefresh.listen(_storeToken);

    // Show foreground FCM messages as local notifications on mobile.
    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n == null) return;
        _localNotifs.show(
          id: msg.hashCode,
          title: n.title,
          body: n.body,
          notificationDetails: _kNotifDetails,
        );
      });
    }
  }

  static Future<void> _storeToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'platform': kIsWeb ? 'web' : 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token)
        .delete();
  }

  static Future<void> scheduleMedication({
    required String medId,
    required String medName,
    required List<String> intakeTimes,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (kIsWeb) return;

    await cancelMedication(medId);

    final now = DateTime.now();
    final window = now.add(const Duration(hours: 48));
    final idBase = medId.hashCode.abs() % 100000;
    int idCounter = 0;

    for (int dayOffset = 0; dayOffset <= 2; dayOffset++) {
      final day = now.add(Duration(days: dayOffset));
      final dayStart = DateTime(day.year, day.month, day.day);
      if (dayStart.isBefore(startDate) || dayStart.isAfter(endDate)) {
        continue;
      }

      for (final t in intakeTimes) {
        final parts = t.split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final scheduledAt =
            DateTime(day.year, day.month, day.day, h, m);
        if (scheduledAt.isBefore(now) || scheduledAt.isAfter(window)) {
          continue;
        }

        await _localNotifs.zonedSchedule(
          id: idBase + idCounter++,
          title: 'Time for $medName',
          body: 'Tap to confirm you took your dose',
          scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
          notificationDetails: _kNotifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  static Future<void> cancelMedication(String medId) async {
    if (kIsWeb) return;
    final base = medId.hashCode.abs() % 100000;
    for (int i = 0; i < 20; i++) {
      await _localNotifs.cancel(id: base + i);
    }
  }
}
