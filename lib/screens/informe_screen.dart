import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../services/report_service.dart';
import '../models/registro.dart';
import '../widgets/planta_card.dart';
import '../widgets/cuidado_card.dart';

class InformeScreen extends StatefulWidget {
  final AppStore store;
  const InformeScreen({super.key, required this.store});
  @override
  State<InformeScreen> createState() => _InformeScreenState();
}

class _InformeScreenState extends State<InformeScreen> {
  final selected = <int>{};
  bool busy = false;
  Future<void> download() async {
    final latest = ultimosRegistros(widget.store.registros);
    final records = widget.store.plantas
        .where((p) => selected.contains(p.id) && latest.containsKey(p.id))
        .map((p) => latest[p.id]!)
        .toList();
    if (records.isEmpty) {
      return;
    }
    setState(() => busy = true);
    try {
      final saved = await widget.store.reports.export(records);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Informe guardado con ${records.length} ${records.length == 1 ? 'planta' : 'plantas'}.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el informe. Inténtalo de nuevo.'),
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
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Descargar informe')),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final latest = ultimosRegistros(widget.store.registros);
          final eligible = widget.store.plantas
              .where((p) => latest.containsKey(p.id))
              .map((p) => p.id!)
              .toSet();
          final count = selected.intersection(eligible).length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [salvia, Color(0xFFFFEDC8)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.summarize_outlined,
                      color: verde,
                      size: 34,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Su crecimiento, en un solo lugar',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Elige las plantas que quieras incluir. Descargaremos un solo PDF con el registro más reciente y la foto de cada una.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (eligible.isNotEmpty)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          if (selected.containsAll(eligible)) {
                            selected.clear();
                          } else {
                            selected.addAll(eligible);
                          }
                        }),
                  child: Text(
                    selected.containsAll(eligible)
                        ? 'Quitar selección'
                        : 'Seleccionar todas',
                  ),
                ),
              if (widget.store.plantas.isEmpty)
                const Vacio(
                  titulo: 'Tu informe empieza con una planta',
                  texto: 'Agrega una planta y crea su primer registro.',
                ),
              ...widget.store.plantas.map((p) {
                final r = latest[p.id];
                return Card(
                  child: CheckboxListTile(
                    value: selected.contains(p.id) && r != null,
                    onChanged: r == null || busy
                        ? null
                        : (v) => setState(
                            () => v!
                                ? selected.add(p.id!)
                                : selected.remove(p.id),
                          ),
                    secondary: SizedBox(
                      width: 48,
                      child: PlantaImagen(
                        especie: p.especie,
                        foto: r?.foto ?? p.foto,
                        height: 58,
                      ),
                    ),
                    title: Text(p.nombre),
                    subtitle: Text(
                      r == null
                          ? 'Sin registros. Crea uno desde su ficha.'
                          : 'Último registro: ${fechaInforme(r.fecha)}',
                    ),
                    activeColor: verde,
                  ),
                );
              }),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: count == 0 || busy ? null : download,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  busy ? 'Preparando informe…' : 'Descargar informe ($count)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Los registros anteriores conservan los datos y la fotografía de cuando se guardaron.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    ),
  );
}
