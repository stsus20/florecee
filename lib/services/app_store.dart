import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

import '../models/planta.dart';
import '../models/especie.dart';
import '../models/cuidado.dart';
import '../models/racha.dart';
import '../models/registro.dart';
import 'report_service.dart';
import 'database_service.dart';
import 'notification_service.dart';

class AppStore extends ChangeNotifier {
  final DatabaseService database;
  final NotificationService notifications;
  final ReportService reports;
  AppStore({
    DatabaseService? database,
    NotificationService? notifications,
    ReportService? reports,
  }) : database = database ?? DatabaseService(),
       notifications = notifications ?? NotificationService(),
       reports = reports ?? ReportService();
  List<Planta> plantas = [];
  List<Especie> catalogo = [];
  List<Cuidado> cuidados = [];
  List<Recordatorio> recordatorios = [];
  List<Map<String, Object?>> diagnosticos = [];
  List<Registro> registros = [];
  String? aviso;
  Future<void>? _refresh;
  Future<void> initialize() async {
    catalogo = (jsonDecode(
      await rootBundle.loadString('lib/assets/data/catalogo_plantas.json'),
    ) as List).map((e) => Especie(Map<String, dynamic>.from(e))).toList();
    await database.open();
    try {
      await notifications.initialize();
    } catch (e) {
      aviso = 'No fue posible activar los recordatorios del sistema. Puedes consultar el calendario.';
    }
    await reload();
  }

  Future<void> reload() async {
    // Serialize refreshes so notification cancellation cannot race scheduling.
    while (_refresh != null) {
      await _refresh;
    }
    final future = _reload();
    _refresh = future;
    try {
      await future;
    } finally {
      _refresh = null;
    }
  }

  Future<void> _reload() async {
    plantas = await database.plantas();
    cuidados = await database.cuidados();
    recordatorios = await database.recordatorios();
    diagnosticos = await database.diagnosticos();
    registros = await database.registros();
    try {
      await notifications.sync(recordatorios, plantas);
      aviso = null;
    } catch (e) {
      debugPrint('Florece: scheduling notifications: $e');
      aviso = 'Los cambios están guardados; no se pudieron programar las notificaciones.';
    }
    notifyListeners();
  }

  Especie especie(String id) => catalogo.firstWhere((s) => s.id == id);
  Recordatorio? proximo(int id) {
    final r = recordatorios.where((r) => r.plantaId == id);
    return r.isEmpty ? null : r.first;
  }

  bool pendiente(int id) => recordatorios.any(
    (r) => r.plantaId == id && !dia(r.fecha).isAfter(dia(DateTime.now())),
  );
  Future<void> save(Planta p) async {
    await database.save(p);
    await reload();
  }

  Future<void> remove(Planta p) async {
    final reportsToRemove = registros.where((r) => r.plantaId == p.id).toList();
    await database.remove(p.id!);
    await reload();
    await deletePhoto(p.foto);
    for (final r in reportsToRemove) {
      await deletePhoto(r.foto);
      await reports.remove(r.pdf);
    }
  }

  Future<void> addRegistro({
    required Planta planta,
    required int hojas,
    required bool amarillas,
    required int porcentaje,
    required double altura,
    required double anchura,
    required String foto,
  }) async {
    final output = await reports.newPath();
    if (!await File(foto).exists()) {
      throw StateError('La fotografía ya no está disponible');
    }
    final s = especie(planta.especie);
    final r = Registro(
      plantaId: planta.id!,
      fecha: DateTime.now(),
      nombre: planta.nombre,
      especie: '${s.nombre} · ${s.cientifico}',
      tipoCuidado: planta.tipoCuidado,
      mito: planta.mito,
      hojas: hojas,
      amarillas: amarillas,
      porcentaje: porcentaje,
      altura: altura,
      anchura: anchura,
      foto: foto,
      pdf: output,
    );
    r.validate();
    try {
      await reports.persist(r);
      await database.saveRegistro(r);
    } catch (_) {
      await reports.remove(output);
      rethrow;
    }
    await reload();
  }

  Future<void> care(
    Planta p,
    TipoCuidado t, {
    int? posponer,
    String notas = '',
  }) async {
    await database.care(p, t, posponer: posponer, notas: notas);
    await reload();
  }

  Future<String> importPhoto(XFile f) async {
    final dir = Directory(
      path.join((await getApplicationDocumentsDirectory()).path, 'plantas'),
    );
    await dir.create(recursive: true);
    final target = path.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}${path.extension(f.path).isEmpty ? '.jpg' : path.extension(f.path)}',
    );
    await f.saveTo(target);
    return target;
  }

  Future<void> deletePhoto(String? file) async {
    if (file == null || await database.photoInUse(file)) {
      return;
    }
    final root = path.join(
      (await getApplicationDocumentsDirectory()).path,
      'plantas',
    );
    if (path.isWithin(root, file) && await File(file).exists()) {
      await File(file).delete();
    }
  }

  int get racha {
    return calcularRacha([
      ...cuidados.map((c) => c.fecha),
      ...registros.map((r) => r.fecha),
    ], DateTime.now());
  }
}
