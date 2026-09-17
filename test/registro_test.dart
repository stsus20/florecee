import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:florece/models/planta.dart';
import 'package:florece/models/registro.dart';
import 'package:florece/services/database_service.dart';
import 'package:florece/services/report_service.dart';

Registro sample({
  int? id,
  int plant = 1,
  int day = 16,
  String name = 'Malvón de prueba',
  String type = 'normal',
  String myth = '',
  int leaves = 12,
  bool yellow = false,
  int percent = 0,
  double height = 32.5,
  double width = 1.2,
  String? photo,
}) => Registro(
  id: id,
  plantaId: plant,
  fecha: DateTime(2026, 9, day, 10, 30),
  nombre: name,
  especie: 'Malvón · Pelargonium × hortorum',
  tipoCuidado: type,
  mito: myth,
  hojas: leaves,
  amarillas: yellow,
  porcentaje: percent,
  altura: height,
  anchura: width,
  foto: photo ?? 'lib/assets/icon/app_icon.png',
  pdf: 'build/qa/registro-prueba.pdf',
);

class SavePicker extends FilePickerPlatform {
  Uint8List? bytes;
  String? mime;
  bool cancel = false;
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.bytes = bytes;
    mime = mimeType;
    return cancel ? null : Uri.parse('content://documents/informe.pdf');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Measurements accept commas; observations reject invalid combinations',
    () {
      expect(parseMedida(' 1,25 '), 1.25);
      expect(() => sample(height: double.nan).validate(), throwsArgumentError);
      expect(() => sample(width: 0).validate(), throwsArgumentError);
      expect(
        () => sample(leaves: 0, yellow: true, percent: 20).validate(),
        throwsArgumentError,
      );
      expect(
        () => sample(yellow: true, percent: 0).validate(),
        throwsArgumentError,
      );
      expect(() => sample(type: 'mito').validate(), throwsArgumentError);
      expect(() => sample(leaves: 0).validate(), returnsNormally);
    },
  );
  test('Latest report is deterministic and excludes earlier observations', () {
    final latest = ultimosRegistros([
      sample(id: 3, plant: 2),
      sample(id: 1, day: 15),
      sample(id: 2),
      sample(id: 4),
    ]);
    expect(latest.length, 2);
    expect(latest[1]!.id, 4);
    expect(latest[2]!.id, 3);
  });
  test('Version 1 migrates without losing plants; snapshots survive edits and reopening', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final directory = await Directory.systemTemp.createTemp(
      'florece_migration_',
    );
    await databaseFactory.setDatabasesPath(directory.path);
    final old = await openDatabase(
      path.join(directory.path, 'florece.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute(
          'CREATE TABLE plantas(id INTEGER PRIMARY KEY AUTOINCREMENT,nombre TEXT NOT NULL,especie TEXT NOT NULL,foto TEXT,ubicacion TEXT NOT NULL,luz TEXT NOT NULL,recipiente TEXT NOT NULL,tamano TEXT NOT NULL,drenaje INTEGER NOT NULL,ultimoRiego TEXT NOT NULL,intervalo INTEGER NOT NULL,notas TEXT NOT NULL)',
        );
      },
    );
    final original = Planta(
      nombre: 'Antes',
      especie: 'malvon',
      ubicacion: 'Exterior',
      luz: 'Sol directo',
      recipiente: 'Maceta',
      tamano: '20 cm',
      drenaje: true,
      ultimoRiego: DateTime(2026, 9, 15),
      intervalo: 4,
    );
    final map = original.toMap()
      ..remove('tipoCuidado')
      ..remove('mito')
      ..remove('id');
    final id = await old.insert('plantas', map);
    await old.close();
    final db = DatabaseService();
    await db.open();
    expect((await db.plantas()).single.tipoCuidado, 'normal');
    await db.saveRegistro(
      sample(
        plant: id,
        name: 'Antes',
        type: 'mito',
        myth: 'Cuidado anotado manualmente',
      ),
    );
    await db.db.update(
      'plantas',
      {'nombre': 'Después', 'tipoCuidado': 'normal'},
      where: 'id=?',
      whereArgs: [id],
    );
    expect(await db.photoInUse('lib/assets/icon/app_icon.png'), isTrue);
    await db.db.close();
    await db.open();
    expect((await db.registros()).single.nombre, 'Antes');
    expect((await db.registros()).single.mito, 'Cuidado anotado manualmente');
    await db.remove(id);
    expect(await db.registros(), isEmpty);
    expect(await db.photoInUse('lib/assets/icon/app_icon.png'), isFalse);
    await db.db.close();
    await directory.delete(recursive: true);
  });
  test(
    'PDF generation handles photos, accents, long myth and a combined report',
    () async {
      final r1 = sample(
        type: 'mito',
        myth: List.filled(
          12,
          'Observación manual del cuidado.',
        ).join(' ').substring(0, 300),
        yellow: true,
        percent: 25,
      );
      final r2 = sample(plant: 2, name: 'Orquídea de prueba', height: 18.2);
      final bytes = await ReportService().generate([r1, r2]);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      await Directory('build/qa').create(recursive: true);
      await File('build/qa/informe-registros.pdf').writeAsBytes(bytes);
    },
  );
  test(
    'PDF export supplies bytes to native save dialog and handles cancellation',
    () async {
      final picker = SavePicker();
      FilePickerPlatform.instance = picker;
      final service = ReportService();
      expect(await service.export([sample()]), isTrue);
      expect(picker.mime, 'application/pdf');
      expect(picker.bytes!.length, greaterThan(1000));
      picker.cancel = true;
      expect(await service.export([sample()]), isFalse);
    },
  );
}
