import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florece/widgets/entrada_suave.dart';
import 'package:florece/widgets/notification_card.dart';
import 'package:florece/services/app_store.dart';
import 'package:florece/services/notification_service.dart';

void main() {
  testWidgets('Reduced motion renders content without animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: EntradaSuave(child: Text('Florece')),
        ),
      ),
    );
    expect(find.text('Florece'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });
  testWidgets('Entry transition ends without a persistent ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: EntradaSuave(child: Text('Jardín'))),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.text('Jardín'), findsOneWidget);
  });
  testWidgets('Notification card fits a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AppStore();
    store.notifications.access = NotificationAccess.channelBlocked;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: NotificationCard(store: store),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Comprobar permiso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
