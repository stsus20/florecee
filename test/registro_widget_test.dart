import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:florece/models/especie.dart';
import 'package:florece/models/planta.dart';
import 'package:florece/models/registro.dart';
import 'package:florece/services/app_store.dart';
import 'package:florece/services/report_service.dart';
import 'package:florece/screens/agregar_planta_screen.dart';
import 'package:florece/screens/registro_screen.dart';
import 'package:florece/screens/informe_screen.dart';
import 'package:florece/widgets/registro_card.dart';

class FakeReports extends ReportService {
  List<Registro> exported = [];
  @override
  Future<bool> export(List<Registro> records, {bool individual = false}) async {
    exported = records;
    return true;
  }
}

Registro reg(int id, int plant, int day) => Registro(
  id: id,
  plantaId: plant,
  fecha: DateTime(2026, 9, day),
  nombre: 'Planta $plant',
  especie: 'Malvón',
  tipoCuidado: 'normal',
  mito: '',
  hojas: 12,
  amarillas: false,
  porcentaje: 0,
  altura: 10,
  anchura: 1,
  foto: 'missing.png',
  pdf: 'sample.pdf',
);
AppStore fixture({FakeReports? reports}) {
  final store = AppStore(reports: reports);
  store.catalogo = (jsonDecode(
    File('lib/assets/data/catalogo_plantas.json').readAsStringSync(),
  ) as List).map((e) => Especie(Map<String, dynamic>.from(e))).toList();
  store.plantas = [
    for (var i = 1; i <= 3; i++)
      Planta(
        id: i,
        nombre: 'Planta $i',
        especie: 'malvon',
        ubicacion: 'Exterior',
        luz: 'Sol directo',
        recipiente: 'Maceta',
        tamano: '20 cm',
        drenaje: true,
        ultimoRiego: DateTime(2026, 9, 15),
        intervalo: 4,
      ),
  ];
  store.registros = [reg(1, 1, 14), reg(3, 2, 16), reg(2, 1, 16)];
  return store;
}

Future<void> scrollTo(WidgetTester t, String text, {double delta = 300}) =>
    t.scrollUntilVisible(
      find.text(text),
      delta,
      scrollable: find.byType(Scrollable).first,
    );
void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets('Mito reveals a mandatory manual description; Normal hides it', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(home: AgregarPlantaScreen(store: fixture())),
    );
    await scrollTo(t, 'Tipo de cuidado');
    await t.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await t.pumpAndSettle();
    await t.tap(find.text('Mito').last);
    await t.pumpAndSettle();
    expect(find.text('¿Qué tipo de mito es?'), findsOneWidget);
    await scrollTo(t, 'Guardar planta');
    await t.tap(find.text('Guardar planta'));
    await t.pump();
    await scrollTo(t, 'Describe el mito', delta: -300);
    expect(find.text('Describe el mito'), findsOneWidget);
    await scrollTo(t, 'Tipo de cuidado', delta: -200);
    await t.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await t.pumpAndSettle();
    await t.tap(find.text('Normal').last);
    await t.pumpAndSettle();
    expect(find.text('¿Qué tipo de mito es?'), findsNothing);
  });
  testWidgets(
    'Observation form requires photo and fields; yellow leaves reveal percentage',
    (t) async {
      final store = fixture();
      await t.pumpWidget(
        MaterialApp(
          home: RegistroScreen(store: store, planta: store.plantas.first),
        ),
      );
      await scrollTo(t, '¿Están amarillas?');
      await t.tap(find.byType(DropdownButtonFormField<bool>));
      await t.pumpAndSettle();
      await t.tap(find.text('Sí').last);
      await t.pumpAndSettle();
      expect(find.text('¿Qué tanto?'), findsOneWidget);
      await scrollTo(t, 'Guardar registro y PDF');
      await t.tap(find.text('Guardar registro y PDF'));
      await t.pump();
      expect(
        find.text('Agrega una fotografía para el registro'),
        findsOneWidget,
      );
      expect(store.registros.length, 3);
    },
  );
  testWidgets(
    'Combined export includes selected latest records only, excluding plants without records',
    (t) async {
      final reports = FakeReports(), store = fixture();
      final exportStore = fixture(reports: reports);
      await t.pumpWidget(MaterialApp(home: InformeScreen(store: exportStore)));
      await scrollTo(t, 'Planta 1');
      await t.tap(find.text('Planta 1'));
      await t.pump();
      await scrollTo(t, 'Descargar informe (1)');
      await t.tap(find.text('Descargar informe (1)'));
      await t.pumpAndSettle();
      expect(reports.exported.map((r) => r.id), [2]);
      expect(store.plantas.length, 3);
      final disabled = t
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .where((w) => w.onChanged == null);
      expect(disabled.length, 1);
    },
  );
  testWidgets('Report cards and export selector fit 320px with enlarged text', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 850);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final store = fixture();
    for (final screen in [
      InformeScreen(store: store),
      Scaffold(
        body: SingleChildScrollView(
          child: RegistroCard(registro: store.registros.first, store: store),
        ),
      ),
      RegistroScreen(store: store, planta: store.plantas.first),
    ]) {
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: screen,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
  });
}
