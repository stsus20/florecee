import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:florece/services/database_service.dart';
import 'package:florece/models/planta.dart';
import 'package:florece/models/cuidado.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'SQLite survives reopening; care reschedules and deletion cascades',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final directory = await Directory.systemTemp.createTemp('florece_test_');
      await databaseFactory.setDatabasesPath(directory.path);
      final service = DatabaseService();
      await service.open();
      final id = await service.save(
        Planta(
          nombre: 'Mi tulipán',
          especie: 'tulipan',
          ubicacion: 'Interior',
          luz: 'Semisombra',
          recipiente: 'Maceta',
          tamano: '25 cm',
          drenaje: true,
          ultimoRiego: DateTime(2026, 9, 10),
          intervalo: 3,
        ),
      );
      final plant = (await service.plantas()).single;
      await service.care(plant, TipoCuidado.riego);
      expect(
        (await service.recordatorios()).single.fecha,
        siguienteRevision(DateTime.now(), 3),
      );
      await service.care(plant, TipoCuidado.humeda, posponer: 2);
      expect(
        (await service.recordatorios()).single.fecha,
        siguienteRevision(DateTime.now(), 2),
      );
      await service.setReminder(
        service.db,
        id,
        TipoCuidado.abono,
        siguienteRevision(DateTime.now(), 10),
      );
      await service.setReminder(
        service.db,
        id,
        TipoCuidado.abono,
        siguienteRevision(DateTime.now(), 12),
      );
      expect((await service.recordatorios()).length, 2);
      await service.diagnosis(id, {
        'sintomas': ['Moho'],
      });
      await service.db.close();
      final reopened = DatabaseService();
      await reopened.open();
      expect((await reopened.plantas()).single.nombre, 'Mi tulipán');
      expect((await reopened.cuidados()).length, 2);
      expect((await reopened.diagnosticos()).length, 1);
      expect((await reopened.recordatorios()).length, 2);
      await reopened.remove(id);
      expect(await reopened.plantas(), isEmpty);
      expect(await reopened.cuidados(), isEmpty);
      expect(await reopened.recordatorios(), isEmpty);
      expect(await reopened.diagnosticos(), isEmpty);
      await reopened.db.close();
      await directory.delete(recursive: true);
    },
  );
}
