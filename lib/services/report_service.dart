import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/registro.dart';

class ReportService {
  Future<Uint8List> generate(List<Registro> records) async {
    if (records.isEmpty) {
      throw ArgumentError('Selecciona al menos una planta con registro');
    }
    final images = <Uint8List?>[];
    for (final r in records) {
      try {
        images.add(await File(r.foto).readAsBytes());
      } catch (_) {
        images.add(null);
      }
    }
    final regular = await rootBundle.load(
      'lib/assets/fonts/LiberationSans-Regular.ttf',
    );
    final bold = await rootBundle.load(
      'lib/assets/fonts/LiberationSans-Bold.ttf',
    );
    return compute(
      buildReport,
      ReportData(
        records,
        images,
        regular.buffer.asUint8List(),
        bold.buffer.asUint8List(),
      ),
    );
  }

  Future<String> newPath() async {
    final dir = Directory(
      path.join((await getApplicationDocumentsDirectory()).path, 'informes'),
    );
    await dir.create(recursive: true);
    return path.join(
      dir.path,
      'registro_${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
  }

  Future<void> persist(Registro r) async {
    await File(r.pdf).writeAsBytes(await generate([r]), flush: true);
  }

  Future<bool> export(List<Registro> records, {bool individual = false}) async {
    Uint8List bytes;
    if (individual &&
        records.length == 1 &&
        await File(records.single.pdf).exists()) {
      bytes = await File(records.single.pdf).readAsBytes();
    } else {
      bytes = await generate(records);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uri = await FilePicker.saveFile(
      fileName: 'florece_${individual ? 'registro' : 'informe'}_$timestamp.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      dialogTitle: 'Guardar informe de Florece',
    );
    return uri != null;
  }

  Future<void> remove(String pdf) async {
    final root = path.join(
      (await getApplicationDocumentsDirectory()).path,
      'informes',
    );
    if (path.isWithin(root, pdf) && await File(pdf).exists()) {
      await File(pdf).delete();
    }
  }
}

class ReportData {
  final List<Registro> records;
  final List<Uint8List?> images;
  final Uint8List regular, bold;
  ReportData(this.records, this.images, this.regular, this.bold);
}

String fechaInforme(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
Future<Uint8List> buildReport(ReportData data) async {
  final doc = pw.Document(
    title: 'Florece - Registro de crecimiento',
    author: 'Florece',
  );
  final green = PdfColor.fromHex('#247344'),
      cream = PdfColor.fromHex('#FFF9E9'),
      sage = PdfColor.fromHex('#E1F0CD');
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(ByteData.sublistView(data.regular)),
    bold: pw.Font.ttf(ByteData.sublistView(data.bold)),
  );
  for (var i = 0; i < data.records.length; i++) {
    final r = data.records[i];
    pw.ImageProvider? photo;
    try {
      if (data.images[i] != null) {
        photo = pw.MemoryImage(data.images[i]!);
      }
    } catch (_) {
      photo = null;
    }
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        maxPages: 20,
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 14),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: sage, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Florece',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.Text(
                'DIARIO DE CRECIMIENTO',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: green,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Observaciones registradas por la persona cuidadora',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Text(
            r.nombre,
            style: pw.TextStyle(
              fontSize: 23,
              fontWeight: pw.FontWeight.bold,
              color: green,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            r.especie,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Registro: ${fechaInforme(r.fecha)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            height: 190,
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: cream,
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: photo != null
                ? pw.Center(child: pw.Image(photo, fit: pw.BoxFit.contain))
                : pw.Center(
                    child: pw.Text(
                      'Fotografía no disponible en este dispositivo',
                    ),
                  ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Observación', 'Respuesta'],
            data: r.tabla,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(color: green),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            oddRowDecoration: pw.BoxDecoration(color: cream),
            border: pw.TableBorder.all(color: sage, width: .6),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1.5),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
            },
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Una fotografía y pequeñas observaciones cuentan la historia de tu planta.',
            style: pw.TextStyle(fontSize: 9, color: green),
          ),
        ],
      ),
    );
  }
  return doc.save();
}
