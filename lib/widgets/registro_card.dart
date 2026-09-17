import 'package:flutter/material.dart';

import '../models/registro.dart';
import '../services/app_store.dart';
import 'planta_card.dart';
import '../services/report_service.dart';

class RegistroTabla extends StatelessWidget {
  final Registro registro;
  const RegistroTabla({super.key, required this.registro});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Table(
      columnWidths: const {0: FlexColumnWidth(1.1), 1: FlexColumnWidth(1)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final row in registro.tabla.asMap().entries)
          TableRow(
            decoration: BoxDecoration(
              color: row.key.isEven
                  ? salvia.withValues(alpha: .6)
                  : Colors.white,
            ),
            children: [
              for (var i = 0; i < 2; i++)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    row.value[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == 0 ? FontWeight.w600 : FontWeight.normal,
                      color: const Color(0xFF244832),
                    ),
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}

class RegistroCard extends StatefulWidget {
  final Registro registro;
  final AppStore store;
  const RegistroCard({super.key, required this.registro, required this.store});
  @override
  State<RegistroCard> createState() => _RegistroCardState();
}

class _RegistroCardState extends State<RegistroCard> {
  bool busy = false;
  Future<void> download() async {
    setState(() => busy = true);
    try {
      final saved = await widget.store.reports.export([
        widget.registro,
      ], individual: true);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF guardado en la ubicación seleccionada.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo descargar el PDF. Inténtalo de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                child: PlantaImagen(
                  especie: 'registro',
                  foto: widget.registro.foto,
                  height: 68,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.registro.nombre,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      fechaInforme(widget.registro.fecha),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const Text(
                      'Registro de crecimiento',
                      style: TextStyle(fontSize: 12, color: verde),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Ver respuestas'),
            children: [
              RegistroTabla(registro: widget.registro),
              const SizedBox(height: 12),
            ],
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : download,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(busy ? 'Preparando…' : 'Descargar PDF'),
          ),
        ],
      ),
    ),
  );
}
