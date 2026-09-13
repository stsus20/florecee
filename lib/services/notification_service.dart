import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/cuidado.dart';
import '../models/planta.dart';

enum NotificationAccess { enabled, denied, channelBlocked, unavailable, error }

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? zoneName,
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       zoneName =
           zoneName ??
           (() async => (await FlutterTimezone.getLocalTimezone()).identifier);
  final FlutterLocalNotificationsPlugin plugin;
  final Future<String> Function() zoneName;
  static const channelId = 'cuidados';
  static const testId = 2147483646;

  bool ready = false;
  bool timezoneReady = false;
  NotificationAccess access = NotificationAccess.unavailable;
  String? schedulingError;
  bool get supported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);
  AndroidFlutterLocalNotificationsPlugin? get android => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  String get statusText => switch (access) {
    NotificationAccess.enabled =>
      schedulingError ??
          'Notificaciones activadas. Un pequeño cuidado, a su tiempo.',
    NotificationAccess.denied =>
      'Las notificaciones están desactivadas para Florece.',
    NotificationAccess.channelBlocked => 'El permiso está activo, pero el canal «Cuidados de plantas» está desactivado.',
    NotificationAccess.unavailable =>
      'Los recordatorios del sistema están disponibles en Android y iOS.',
    NotificationAccess.error =>
      'No pudimos comprobar las notificaciones. Vuelve a intentarlo.',
  };

  Future<void> initialize() async {
    if (!supported) {
      access = NotificationAccess.unavailable;
      return;
    }
    if (!ready) {
      final initialized = await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      if (initialized == false) {
        throw StateError(
          'No se pudo inicializar el servicio de notificaciones',
        );
      }
      ready = true;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'Cuidados de plantas',
          description: 'Revisiones suaves para acompañar a tus plantas',
          importance: Importance.defaultImportance,
        ),
      );
    }
    await refreshAccess();
  }

  Future<NotificationAccess> refreshAccess() async {
    if (!supported) {
      return access = NotificationAccess.unavailable;
    }
    try {
      if (!ready) {
        await initialize();
        return access;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final enabled = await android?.areNotificationsEnabled();
        if (enabled == null) {
          return access = NotificationAccess.error;
        }
        if (!enabled) {
          return access = NotificationAccess.denied;
        }
        final channels = await android?.getNotificationChannels();
        if (channels?.any(
              (c) => c.id == channelId && c.importance == Importance.none,
            ) ??
            false) {
          return access = NotificationAccess.channelBlocked;
        }
        return access = NotificationAccess.enabled;
      }
      final permissions = await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      if (permissions == null) {
        return access = NotificationAccess.error;
      }
      return access = permissions.isEnabled || permissions.isProvisionalEnabled
          ? NotificationAccess.enabled
          : NotificationAccess.denied;
    } catch (e) {
      debugPrint('Florece: notification access: $e');
      return access = NotificationAccess.error;
    }
  }

  Future<bool> request() async {
    final current = await refreshAccess();
    if (current == NotificationAccess.enabled) {
      return true;
    }
    if (current != NotificationAccess.denied) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await android?.requestNotificationsPermission();
    } else {
      await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return await refreshAccess() == NotificationAccess.enabled;
  }

  Future<void> openSettings() async {
    if (!supported) {
      return;
    }
    await plugin.openAppNotificationSettings();
  }

  Future<void> configureTimezone() async {
    timezoneReady = false;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await zoneName()));
      timezoneReady = true;
      schedulingError = null;
    } catch (e) {
      // A timezone failure is not a notification permission failure.
      debugPrint('Florece: timezone: $e');
      schedulingError = 'El permiso está activo. No pudimos leer la zona horaria; activa la fecha y zona automáticas y vuelve a abrir Florece.';
    }
  }

  NotificationDetails details(TipoCuidado type, String message) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Cuidados de plantas',
          channelDescription: 'Revisiones suaves para acompañar a tus plantas',
          icon: 'ic_notification',
          color: const Color(0xFF365F45),
          largeIcon: const DrawableResourceAndroidBitmap('notification_brand'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(
            message,
            summaryText: 'Florece · Tu rincón verde',
          ),
          category: AndroidNotificationCategory.reminder,
          onlyAlertOnce: true,
        ),
        iOS: const DarwinNotificationDetails(
          threadIdentifier: 'cuidados',
          presentAlert: true,
          presentSound: true,
        ),
      );
  String message(TipoCuidado type) => switch (type) {
    TipoCuidado.abono => 'Un momento para nutrir su crecimiento. Revisa su guía antes de fertilizar.',
    TipoCuidado.trasplante => 'Dale espacio para crecer. Revisa sus raíces y la maceta antes de trasplantar.',
    _ => 'Toca la tierra y revisa su humedad. Si sigue húmeda, espera un poco más antes de regar.',
  };
  Future<void> testNotification() async {
    if (await refreshAccess() != NotificationAccess.enabled) {
      throw StateError(statusText);
    }
    const body =
        'Tus recordatorios tienen un nuevo brote. Así te acompañará Florece en el cuidado de tus plantas.';
    await plugin.show(
      id: testId,
      title: 'Florece · Todo listo 🌿',
      body: body,
      notificationDetails: details(TipoCuidado.revision, body),
    );
  }

  Future<void> sync(List<Recordatorio> reminders, List<Planta> plants) async {
    schedulingError = null;
    final currentAccess = await refreshAccess();
    if (!ready) {
      return;
    }
    final pending = await plugin.pendingNotificationRequests();
    final ids = reminders.map((r) => r.id).toSet();
    for (final old in pending) {
      if (old.id != testId && !ids.contains(old.id)) {
        await plugin.cancel(id: old.id);
      }
    }
    if (currentAccess != NotificationAccess.enabled) {
      return;
    }
    await configureTimezone();
    if (!timezoneReady) {
      return;
    }
    final now = DateTime.now();
    for (final r in reminders) {
      if (!r.fecha.isAfter(now)) {
        continue;
      }
      final matches = plants.where((p) => p.id == r.plantaId);
      if (matches.isEmpty) {
        continue;
      }
      final plant = matches.first;
      final signature = jsonEncode([
        r.plantaId,
        r.tipo.name,
        r.fecha.toIso8601String(),
        plant.nombre,
        tz.local.name,
      ]);
      final exists = pending.any((p) => p.id == r.id && p.payload == signature);
      if (exists) {
        continue;
      }
      final text = message(r.tipo);
      await plugin.zonedSchedule(
        id: r.id,
        title: '${plant.nombre} · ${r.tipo.tarea}',
        body: text,
        scheduledDate: tz.TZDateTime.from(r.fecha, tz.local),
        notificationDetails: details(r.tipo, text),
        payload: signature,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
