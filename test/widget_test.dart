import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:florece/models/especie.dart';
import 'package:florece/models/planta.dart';
import 'package:florece/services/app_store.dart';
import 'package:florece/screens/inicio_screen.dart';
import 'package:florece/screens/calendario_screen.dart';
import 'package:florece/screens/catalogo_screen.dart';
import 'package:florece/screens/diagnostico_screen.dart';
import 'package:florece/screens/agregar_planta_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  AppStore fixture() {
    final store = AppStore();
    store.catalogo = (jsonDecode(
      File('lib/assets/data/catalogo_plantas.json').readAsStringSync(),
    ) as List).map((e) => Especie(Map<String, dynamic>.from(e))).toList();
    store.plantas = [
      Planta(
        id: 1,
        nombre: 'Tulipán de la ventana',
        especie: 'tulipan',
        ubicacion: 'Interior',
        luz: 'Semisombra',
        recipiente: 'Maceta',
        tamano: '25 cm',
        drenaje: true,
        ultimoRiego: DateTime.now(),
        intervalo: 3,
      ),
    ];
    return store;
  }

  test('Catalog has all 16 complete species', () {
    final s = fixture();
    expect(s.catalogo.length, 16);
    for (final e in s.catalogo) {
      for (final key in [
        'id',
        'nombre',
        'cientifico',
        'descripcion',
        'luz',
        'riego',
        'intervalo',
        'floracion',
        'fertilizacion',
        'sustrato',
        'maceta',
        'suelo',
        'drenaje',
        'consejos',
        'problemas',
      ]) {
        expect(e.data[key], isNotNull);
      }
    }
  });
  testWidgets('Malvones can be found without accents', (tester) async {
    final store = fixture();
    final malvon = store.catalogo.singleWhere((s) => s.id == 'malvon');
    expect(malvon.cientifico, 'Pelargonium × hortorum');
    expect(malvon.texto('fuentes'), isNotEmpty);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CatalogoScreen(store: store)),
      ),
    );
    await tester.enterText(find.byType(TextField), 'malvones');
    await tester.pumpAndSettle();
    expect(find.text('Malvón'), findsOneWidget);
    await tester.tap(find.text('Malvón'));
    await tester.pumpAndSettle();
    expect(find.text('Pelargonium × hortorum'), findsOneWidget);
  });
  testWidgets('Main screens fit 320px with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = fixture();
    for (final screen in [
      InicioScreen(store: store),
      CalendarioScreen(store: store),
      CatalogoScreen(store: store),
      DiagnosticoScreen(store: store),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(1.2),
            ),
            child: Scaffold(body: screen),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Diagnosis allows selecting plant and multiple symptoms', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DiagnosticoScreen(store: fixture())),
      ),
    );
    await tester.tap(find.text('Tulipán de la ventana'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Continuar'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hojas amarillas'));
    await tester.tap(find.text('Manchas'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Continuar'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Conozcamos sus condiciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Plant form rejects missing name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AgregarPlantaScreen(store: fixture())),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Guardar planta'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Guardar planta'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Escribe un nombre'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Escribe un nombre'), findsOneWidget);
  });
}
