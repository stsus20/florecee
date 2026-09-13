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
import 'database_service.dart';
import 'notification_service.dart';

class AppStore extends ChangeNotifier {
  final DatabaseService database;
  final NotificationService notifications;
  AppStore({DatabaseService? database, NotificationService? notifications})
    : database = database ?? DatabaseService(),
      notifications = notifications ?? NotificationService();
  List<Planta> plantas = [];
  List<Especie> catalogo = [];
  List<Cuidado> cuidados = [];
  List<Recordatorio> recordatorios = [];
  List<Map<String, Object?>> diagnosticos = [];
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
    await database.remove(p.id!);
    await reload();
    await deletePhoto(p.foto);
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
    if (file == null || plantas.any((p) => p.foto == file)) {
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
    final days = cuidados.map((c) => dia(c.fecha)).toSet();
    var date = dia(DateTime.now());
    if (!days.contains(date)) {
      date = DateTime(date.year, date.month, date.day - 1);
    }
    var count = 0;
    while (days.contains(date)) {
      count++;
      date = DateTime(date.year, date.month, date.day - 1);
    }
    return count;
  }
}
