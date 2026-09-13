import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:florece/services/notification_service.dart';
import 'package:florece/models/planta.dart';
import 'package:florece/models/cuidado.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  late Map<int, Map<String, Object?>> pending;
  bool enabled = true;
  bool blocked = false;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    pending = {};
    enabled = true;
    blocked = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final args = call.arguments;
          switch (call.method) {
            case 'initialize':
              return true;
            case 'areNotificationsEnabled':
              return enabled;
            case 'getNotificationChannels':
              return blocked
                  ? [
                      {
                        'id': 'cuidados',
                        'name': 'Cuidados de plantas',
                        'importance': 0,
                        'playSound': true,
                        'enableVibration': true,
                        'showBadge': true,
                        'enableLights': false,
                        'bypassDnd': false,
                        'ledColor': 0,
                        'audioAttributesUsage': 5,
                      },
                    ]
                  : [];
            case 'requestNotificationsPermission':
              return false;
            case 'pendingNotificationRequests':
              return pending.values.toList();
            case 'zonedSchedule':
              final a = Map<String, Object?>.from(args as Map);
              pending[a['id'] as int] = {
                'id': a['id'],
                'title': a['title'],
                'body': a['body'],
                'payload': a['payload'],
              };
              return null;
            case 'cancel':
              pending.remove((args as Map)['id']);
              return null;
            default:
              return null;
          }
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'Permission granted in Settings does not request permission again',
    () async {
      final service = NotificationService(
        zoneName: () async => 'America/Mexico_City',
      );
      expect(await service.request(), isTrue);
      expect(
        calls.any((c) => c.method == 'requestNotificationsPermission'),
        isFalse,
      );
    },
  );
  test('Timezone failure is not reported as permission denial and test still works', () async {
    final service = NotificationService(zoneName: () async => 'Unknown/Zone');
    await service.initialize();
    await service.sync([], []);
    expect(service.access, NotificationAccess.enabled);
    expect(service.timezoneReady, isFalse);
    expect(service.schedulingError, contains('zona horaria'));
    await service.testNotification();
    expect(calls.any((c) => c.method == 'show'), isTrue);
  });
  test(
    'Denied access refreshes correctly after returning from Settings',
    () async {
      enabled = false;
      final service = NotificationService();
      expect(await service.refreshAccess(), NotificationAccess.denied);
      enabled = true;
      expect(await service.refreshAccess(), NotificationAccess.enabled);
    },
  );
  test('Disabled care channel is distinguished from app permission', () async {
    blocked = true;
    final service = NotificationService();
    expect(await service.refreshAccess(), NotificationAccess.channelBlocked);
  });
  test(
    'Refresh preserves unchanged schedule; edit replaces and deletion cancels',
    () async {
      final service = NotificationService(
        zoneName: () async => 'America/Mexico_City',
      );
      final plant = Planta(
        id: 1,
        nombre: 'Tulipán',
        especie: 'tulipan',
        ubicacion: 'Interior',
        luz: 'Semisombra',
        recipiente: 'Maceta',
        tamano: '20 cm',
        drenaje: true,
        ultimoRiego: DateTime(2026, 9, 12),
        intervalo: 3,
      );
      final r = Recordatorio.fromMap({
        'id': 12,
        'plantaId': 1,
        'tipo': 'revision',
        'fecha': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      });
      await service.sync([r], [plant]);
      await service.sync([r], [plant]);
      expect(calls.where((c) => c.method == 'zonedSchedule').length, 1);
      final updated = Recordatorio.fromMap({
        'id': 12,
        'plantaId': 1,
        'tipo': 'revision',
        'fecha': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      });
      await service.sync([updated], [plant]);
      expect(calls.where((c) => c.method == 'zonedSchedule').length, 2);
      await service.sync([], []);
      expect(pending, isEmpty);
      expect(calls.any((c) => c.method == 'cancelAll'), isFalse);
    },
  );
}
