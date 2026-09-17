import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../models/planta.dart';
import '../models/cuidado.dart';
import '../widgets/planta_card.dart';
import '../widgets/cuidado_card.dart';
import 'agregar_planta_screen.dart';
import 'catalogo_screen.dart';
import 'registro_screen.dart';
import '../widgets/registro_card.dart';

class DetallePlantaScreen extends StatefulWidget {
  final AppStore store;
  final int id;
  const DetallePlantaScreen({super.key, required this.store, required this.id});
  @override
  State<DetallePlantaScreen> createState() => _DetallePlantaScreenState();
}

class _DetallePlantaScreenState extends State<DetallePlantaScreen> {
  bool busy = false;
  Future<void> care(Planta p, TipoCuidado t) async {
    int? delay;
    if (t == TipoCuidado.humeda) {
      delay = await showDialog<int>(
        context: context,
        builder: (c) => SimpleDialog(
          title: const Text('¿Cuándo revisamos de nuevo?'),
          children: [1, 2, 3]
              .map(
                (d) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(c, d),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text('En $d ${d == 1 ? 'día' : 'días'}'),
                  ),
                ),
              )
              .toList(),
        ),
      );
      if (delay == null) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => busy = true);
    await ejecutar(context, () async {
      await widget.store.care(
        p,
        t,
        posponer: delay,
        notas: delay != null ? 'Revisión pospuesta $delay días' : '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.label}: guardado en el historial')),
        );
      }
    });
    if (mounted) {
      setState(() => busy = false);
    }
  }

  Future<void> reminder(Planta p) async {
    final type = await showDialog<TipoCuidado>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Programar cuidado'),
        children:
            [
                  TipoCuidado.riego,
                  TipoCuidado.abono,
                  TipoCuidado.revision,
                  TipoCuidado.trasplante,
                ]
                .map(
                  (t) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(c, t),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(t.tarea),
                    ),
                  ),
                )
                .toList(),
      ),
    );
    if (type == null || !mounted) {
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) {
      return;
    }
    await ejecutar(context, () async {
      await widget.store.database.setReminder(
        widget.store.database.db,
        p.id!,
        type,
        mismoDia(date, DateTime.now()) && DateTime.now().hour >= 9
            ? DateTime.now().add(const Duration(minutes: 1))
            : DateTime(date.year, date.month, date.day, 9),
      );
      await widget.store.reload();
    });
  }

  Future<void> remove(Planta p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('¿Eliminar ${p.nombre}?'),
        content: const Text(
          'También se eliminarán su historial, registros, PDFs internos, diagnósticos, fotografías y recordatorios. Los PDFs que ya descargaste se conservarán. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    await ejecutar(context, () async {
      await widget.store.remove(p);
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final found = widget.store.plantas.where((p) => p.id == widget.id);
      if (found.isEmpty) {
        return const Scaffold(body: SizedBox.shrink());
      }
      final p = found.first, s = widget.store.especie(p.especie);
      final next = widget.store.proximo(p.id!);
      final history = widget.store.cuidados
          .where((c) => c.plantaId == p.id)
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Florece',
            style: TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AgregarPlantaScreen(store: widget.store, planta: p),
                    ),
                  );
                } else {
                  remove(p);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar planta')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar planta')),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PlantaImagen(especie: p.especie, foto: p.foto, height: 260),
            const SizedBox(height: 20),
            Text(p.nombre, style: Theme.of(context).textTheme.headlineLarge),
            Text(
              '${s.nombre} · ${s.cientifico}',
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.eco, size: 18),
                label: Text(
                  widget.store.pendiente(p.id!)
                      ? 'Necesita revisión'
                      : 'Cuidados al día',
                ),
                backgroundColor: salvia,
              ),
            ),
            Text(s.texto('descripcion')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: salvia.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de cuidado: ${p.tipoCuidado == 'mito' ? 'Mito' : 'Normal'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: verde,
                    ),
                  ),
                  if (p.tipoCuidado == 'mito') ...[
                    const SizedBox(height: 6),
                    Text(p.mito),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RegistroScreen(store: widget.store, planta: p),
                ),
              ),
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text('Registro'),
            ),
            const SizedBox(height: 18),
            if (next != null)
              CuidadoCard(
                titulo: 'Próxima acción',
                subtitulo: '${next.tipo.tarea}\n${fechaCorta(next.fecha)}',
                tipo: next.tipo,
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: TipoCuidado.values
                  .map(
                    (t) => FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorCuidado(t).withValues(alpha: .13),
                        foregroundColor: const Color(0xFF244832),
                      ),
                      onPressed: busy ? null : () => care(p, t),
                      icon: Icon(iconCuidado(t), color: colorCuidado(t)),
                      label: Text(t.label),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => reminder(p),
              icon: const Icon(Icons.event_available),
              label: const Text('Programar cuidado'),
            ),
            GuiaEspecie(especie: s),
            ExpansionTile(
              title: const Text('Así vive tu planta'),
              children: [
                ListTile(
                  title: Text('${p.ubicacion} · ${p.luz}'),
                  subtitle: Text(
                    '${p.recipiente} · ${p.tamano}\nDrenaje: ${p.drenaje ? 'sí' : 'no'}\nRevisión cada ${p.intervalo} días\n${p.notas}',
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              'Historial',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Registros de crecimiento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!widget.store.registros.any((r) => r.plantaId == p.id))
              const Vacio(
                titulo: 'Su historia está por escribirse',
                texto: 'Pulsa Registro para guardar las medidas, la foto y su informe PDF.',
              ),
            ...widget.store.registros
                .where((r) => r.plantaId == p.id)
                .map(
                  (r) => RegistroCard(
                    key: ValueKey(r.id),
                    registro: r,
                    store: widget.store,
                  ),
                ),
            const SizedBox(height: 18),
            Text(
              'Cuidados realizados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (history.isEmpty)
              const Vacio(
                titulo: 'Cada cuidado deja huella',
                texto: 'Registra el primero con los botones de arriba.',
              ),
            ...history.map(
              (c) => CuidadoCard(
                titulo: c.tipo.label,
                subtitulo:
                    '${fechaCorta(c.fecha)}${c.notas.isEmpty ? '' : ' · ${c.notas}'}',
                tipo: c.tipo,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
