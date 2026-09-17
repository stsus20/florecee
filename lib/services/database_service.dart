import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/planta.dart';
import '../models/cuidado.dart';
import '../models/registro.dart';

class DatabaseService {
  late Database db;
  Future<void> open() async {
    db = await openDatabase(
      p.join(await getDatabasesPath(), 'florece.db'),
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, v) async {
        await db.execute(
          'CREATE TABLE plantas(id INTEGER PRIMARY KEY AUTOINCREMENT,nombre TEXT NOT NULL,especie TEXT NOT NULL,foto TEXT,ubicacion TEXT NOT NULL,luz TEXT NOT NULL,recipiente TEXT NOT NULL,tamano TEXT NOT NULL,drenaje INTEGER NOT NULL,ultimoRiego TEXT NOT NULL,intervalo INTEGER NOT NULL CHECK(intervalo>0),notas TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE cuidados(id INTEGER PRIMARY KEY AUTOINCREMENT,plantaId INTEGER NOT NULL REFERENCES plantas(id) ON DELETE CASCADE,tipo TEXT NOT NULL,fecha TEXT NOT NULL,notas TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE recordatorios(id INTEGER PRIMARY KEY AUTOINCREMENT,plantaId INTEGER NOT NULL REFERENCES plantas(id) ON DELETE CASCADE,tipo TEXT NOT NULL,fecha TEXT NOT NULL,UNIQUE(plantaId,tipo))',
        );
        await db.execute(
          'CREATE TABLE diagnosticos(id INTEGER PRIMARY KEY AUTOINCREMENT,plantaId INTEGER NOT NULL REFERENCES plantas(id) ON DELETE CASCADE,fecha TEXT NOT NULL,datos TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE INDEX cuidados_planta_fecha ON cuidados(plantaId,fecha)',
        );
        await _upgradeV2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _upgradeV2(db);
        }
      },
    );
  }

  Future<void> _upgradeV2(DatabaseExecutor db) async {
    await db.execute(
      "ALTER TABLE plantas ADD COLUMN tipoCuidado TEXT NOT NULL DEFAULT 'normal' CHECK(tipoCuidado IN ('normal','mito'))",
    );
    await db.execute(
      "ALTER TABLE plantas ADD COLUMN mito TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      'CREATE TABLE registros(id INTEGER PRIMARY KEY AUTOINCREMENT,plantaId INTEGER NOT NULL REFERENCES plantas(id) ON DELETE CASCADE,fecha TEXT NOT NULL,nombre TEXT NOT NULL,especie TEXT NOT NULL,tipoCuidado TEXT NOT NULL,mito TEXT NOT NULL,hojas INTEGER NOT NULL CHECK(hojas>=0),amarillas INTEGER NOT NULL CHECK(amarillas IN (0,1)),porcentaje INTEGER NOT NULL CHECK(porcentaje BETWEEN 0 AND 100),altura REAL NOT NULL CHECK(altura>0),anchura REAL NOT NULL CHECK(anchura>0),foto TEXT NOT NULL,pdf TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE INDEX registros_planta_fecha ON registros(plantaId,fecha DESC,id DESC)',
    );
  }

  Future<List<Registro>> registros() async => (await db.query(
    'registros',
    orderBy: 'fecha DESC,id DESC',
  )).map(Registro.fromMap).toList();
  Future<int> saveRegistro(Registro r) async {
    r.validate();
    return db.insert('registros', r.toMap()..remove('id'));
  }

  Future<bool> photoInUse(String photo) async {
    final rows = await db.rawQuery(
      'SELECT foto FROM plantas WHERE foto=? UNION ALL SELECT foto FROM registros WHERE foto=? LIMIT 1',
      [photo, photo],
    );
    return rows.isNotEmpty;
  }

  Future<List<Planta>> plantas() async => (await db.query(
    'plantas',
    orderBy: 'id DESC',
  )).map(Planta.fromMap).toList();
  Future<List<Cuidado>> cuidados() async => (await db.query(
    'cuidados',
    orderBy: 'fecha DESC',
  )).map(Cuidado.fromMap).toList();
  Future<List<Recordatorio>> recordatorios() async => (await db.query(
    'recordatorios',
    orderBy: 'fecha',
  )).map(Recordatorio.fromMap).toList();
  Future<List<Map<String, Object?>>> diagnosticos() =>
      db.query('diagnosticos', orderBy: 'fecha DESC');
  Future<void> setReminder(
    DatabaseExecutor tx,
    int id,
    TipoCuidado tipo,
    DateTime fecha,
  ) async {
    final changed = await tx.update(
      'recordatorios',
      {'fecha': fecha.toIso8601String()},
      where: 'plantaId=? AND tipo=?',
      whereArgs: [id, tipo.name],
    );
    if (changed == 0) {
      await tx.insert('recordatorios', {
        'plantaId': id,
        'tipo': tipo.name,
        'fecha': fecha.toIso8601String(),
      });
    }
  }

  Future<int> save(Planta planta) => db.transaction((tx) async {
    if (!['normal', 'mito'].contains(planta.tipoCuidado) ||
        (planta.tipoCuidado == 'mito' && planta.mito.trim().isEmpty)) {
      throw ArgumentError('Indica el tipo de cuidado y el mito');
    }
    final m = planta.toMap()..remove('id');
    final previous = planta.id == null
        ? null
        : (await tx.query(
            'plantas',
            where: 'id=?',
            whereArgs: [planta.id],
          )).first;
    final id = planta.id ?? await tx.insert('plantas', m);
    if (planta.id != null) {
      await tx.update('plantas', m, where: 'id=?', whereArgs: [id]);
    }
    if (previous == null ||
        previous['intervalo'] != planta.intervalo ||
        previous['ultimoRiego'] != planta.ultimoRiego.toIso8601String()) {
      await setReminder(
        tx,
        id,
        TipoCuidado.revision,
        siguienteRevision(planta.ultimoRiego, planta.intervalo),
      );
    }
    return id;
  });
  Future<void> remove(int id) =>
      db.delete('plantas', where: 'id=?', whereArgs: [id]);
  Future<void> care(
    Planta planta,
    TipoCuidado tipo, {
    int? posponer,
    String notas = '',
  }) async {
    final now = DateTime.now();
    await db.transaction((tx) async {
      await tx.insert('cuidados', {
        'plantaId': planta.id,
        'tipo': tipo.name,
        'fecha': now.toIso8601String(),
        'notas': notas,
      });
      if (tipo == TipoCuidado.riego) {
        await tx.update(
          'plantas',
          {'ultimoRiego': now.toIso8601String()},
          where: 'id=?',
          whereArgs: [planta.id],
        );
      }
      if ([
        TipoCuidado.riego,
        TipoCuidado.revision,
        TipoCuidado.humeda,
      ].contains(tipo)) {
        await tx.delete(
          'recordatorios',
          where: 'plantaId=? AND tipo=?',
          whereArgs: [planta.id, TipoCuidado.riego.name],
        );
        await setReminder(
          tx,
          planta.id!,
          TipoCuidado.revision,
          siguienteRevision(now, posponer ?? planta.intervalo),
        );
      } else {
        await tx.delete(
          'recordatorios',
          where: 'plantaId=? AND tipo=?',
          whereArgs: [planta.id, tipo.name],
        );
      }
    });
  }

  Future<void> diagnosis(int id, Map<String, dynamic> data) async {
    await db.insert('diagnosticos', {
      'plantaId': id,
      'fecha': DateTime.now().toIso8601String(),
      'datos': jsonEncode(data),
    });
  }
}
