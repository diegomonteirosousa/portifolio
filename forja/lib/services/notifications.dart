import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';

/// Lembretes locais (não precisam de servidor nem de login).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _restId = 999;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'forja_lembretes',
      'Lembretes',
      channelDescription: 'Lembretes de treino e de água',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFC6F432),
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(_localLocation());
      // Ícone de notificação monocromático (criado pelo tool/setup.dart).
      // Se ele não existir, usa o ícone do app.
      for (final icon in const ['@drawable/ic_stat_forja', '@mipmap/ic_launcher']) {
        try {
          await _plugin.initialize(InitializationSettings(
            android: AndroidInitializationSettings(icon),
            iOS: const DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ));
          _ready = true;
          break;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  /// Usa o fuso pelo deslocamento do aparelho (ex.: UTC-3 -> Etc/GMT+3).
  tz.Location _localLocation() {
    final offset = DateTime.now().timeZoneOffset;
    if (offset.inMinutes % 60 != 0) return tz.UTC;
    final h = offset.inHours;
    if (h == 0) return tz.UTC;
    // Nos fusos "Etc" o sinal é invertido.
    final name = h < 0 ? 'Etc/GMT+${-h}' : 'Etc/GMT-$h';
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.UTC;
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (e) {
      debugPrint('Permissão de notificação: $e');
    }
    return false;
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  Future<void> reschedule(ReminderSettings r) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (r.workoutOn) {
        for (final day in r.workoutDays) {
          await _plugin.zonedSchedule(
            100 + day,
            'Hora de treinar 💪',
            'Seu treino está te esperando. Bora manter a ofensiva!',
            _nextWeekday(day, r.workoutHour, r.workoutMinute),
            _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
      if (r.waterOn) {
        for (var h = r.waterFrom; h <= r.waterTo; h += r.waterEveryHours) {
          await _plugin.zonedSchedule(
            200 + h,
            'Beba água 💧',
            'Um copo agora te deixa mais perto da meta do dia.',
            _nextTime(h, 0),
            _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    } catch (e) {
      debugPrint('Falha ao agendar lembretes: $e');
    }
  }

  /// Aviso de fim do descanso, caso o app esteja em segundo plano.
  Future<void> scheduleRestEnd(int seconds) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_restId);
      await _plugin.zonedSchedule(
        _restId,
        'Descanso concluído ⏱️',
        'Próxima série!',
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Falha ao agendar descanso: $e');
    }
  }

  Future<void> cancelRestEnd() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_restId);
    } catch (_) {}
  }

  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!d.isAfter(now)) d = d.add(const Duration(days: 1));
    return d;
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    var d = _nextTime(hour, minute);
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }
}
