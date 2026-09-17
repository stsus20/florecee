import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florece/models/racha.dart';
import 'package:florece/widgets/racha_card.dart';

void main() {
  test('Streak stages have inclusive limits and stop changing after 30', () {
    for (final entry in {
      0: EtapaRacha.semilla,
      1: EtapaRacha.brote,
      10: EtapaRacha.brote,
      11: EtapaRacha.tallo,
      20: EtapaRacha.tallo,
      21: EtapaRacha.flor,
      30: EtapaRacha.flor,
      31: EtapaRacha.flor,
      365: EtapaRacha.flor,
    }.entries) {
      expect(CrecimientoRacha(entry.key).etapa, entry.value);
    }
    expect(
      CrecimientoRacha(31).diasVisuales,
      CrecimientoRacha(30).diasVisuales,
    );
    expect(CrecimientoRacha(365).progreso, 1);
  });
  test(
    'Care days are unique, gaps reset and today is allowed to be incomplete',
    () {
      final now = DateTime(2026, 9, 13);
      expect(
        calcularRacha([
          DateTime(2026, 9, 12),
          DateTime(2026, 9, 12, 18),
          DateTime(2026, 9, 11),
        ], now),
        2,
      );
      expect(calcularRacha([DateTime(2026, 9, 11)], now), 0);
      expect(calcularRacha([now, DateTime(2026, 9, 11)], now), 1);
      expect(calcularRacha([DateTime(2026, 9, 14)], now), 0);
      expect(
        calcularRacha([
          DateTime(2025, 12, 31),
          DateTime(2026, 1, 1),
        ], DateTime(2026, 1, 1)),
        2,
      );
    },
  );
  testWidgets('Every growth stage fits small screens and animations finish', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final day in [0, 1, 10, 11, 20, 21, 30, 31, 365]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RachaCard(dias: day),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
  });
  testWidgets('Reduced motion paints mature daisy immediately', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SizedBox(
            width: 180,
            height: 200,
            child: MargaritaRacha(dias: 40),
          ),
        ),
      ),
    );
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<MargaritaPainter>()
        .single;
    expect(painter.dias, 30);
  });
  if (const bool.fromEnvironment('RENDER_QA')) {
    testWidgets('Export growth stage design for visual review', (tester) async {
      final font = File('C:/Windows/Fonts/segoeui.ttf');
      await tester.runAsync(() async {
        if (await font.exists()) {
          final loader = FontLoader('Preview');
          loader.addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          );
          await loader.load();
        }
      });
      tester.view.physicalSize = const Size(1440, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Preview', useMaterial3: true),
          home: Scaffold(
            backgroundColor: const Color(0xFFFFF9E9),
            body: RepaintBoundary(
              key: key,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final days in [0, 5, 15, 30])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: RachaCard(dias: days),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('build/qa');
        await dir.create(recursive: true);
        await File('${dir.path}/racha-etapas.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
