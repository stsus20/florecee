import '../widgets/notification_card.dart';
import '../widgets/racha_card.dart';

import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../models/cuidado.dart';
import '../widgets/planta_card.dart';
import '../widgets/cuidado_card.dart';
import 'agregar_planta_screen.dart';
import 'detalle_planta_screen.dart';
import 'informe_screen.dart';

class InicioScreen extends StatelessWidget {
  final AppStore store;
  const InicioScreen({super.key, required this.store});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = {
      ...store.cuidados
          .where((c) => mismoDia(c.fecha, now))
          .map((c) => c.plantaId),
      ...store.registros
          .where((r) => mismoDia(r.fecha, now))
          .map((r) => r.plantaId),
    }.length;
    final week = dia(now).subtract(Duration(days: now.weekday - 1));
    final counts = <int, int>{};
    for (final c in store.cuidados) {
      counts.update(c.plantaId, (v) => v + 1, ifAbsent: () => 1);
    }
    for (final r in store.registros) {
      counts.update(r.plantaId, (v) => v + 1, ifAbsent: () => 1);
    }
    final most = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Florece',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: verde,
                    ),
                  ),
                  const Text(
                    'Pequeños cuidados, grandes historias',
                    style: TextStyle(color: verde),
                  ),
                ],
              ),
            ),
            const Icon(Icons.spa, size: 58, color: verde),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          now.hour < 12 ? 'Buenos días ☀' : 'Tu rincón verde',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Hoy es un gran día para cuidar de tus plantas.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => InformeScreen(store: store),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(color: Color(0xFFB7D59A)),
          ),
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Descargar informe'),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F0C1), Color(0xFFF8EDBC)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus plantas hoy',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  stat('${store.plantas.length}', 'Plantas'),
                  stat(
                    '${store.plantas.where((p) => store.pendiente(p.id!)).length}',
                    'Por revisar',
                  ),
                  stat('$today', 'Atendidas hoy'),
                  stat('${store.recordatorios.length}', 'Próximos cuidados'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        RachaCard(dias: store.racha),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Mis plantas',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: 'Agregar planta',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AgregarPlantaScreen(store: store),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (store.plantas.isEmpty)
          const Vacio(
            titulo: 'Aquí empieza tu jardín',
            texto: 'Agrega tu primera planta y acompaña su crecimiento.',
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth < 350
                ? 1
                : constraints.maxWidth < 650
                ? 2
                : 3;
            final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: store.plantas.map((p) {
                final next = store.proximo(p.id!);
                return SizedBox(
                  width: width,
                  child: PlantaCard(
                    planta: p,
                    cientifico: store.especie(p.especie).cientifico,
                    accion: next == null
                        ? 'Sin cuidados pendientes'
                        : '${next.tipo.tarea}\n${fechaCorta(next.fecha)}',
                    pendiente: store.pendiente(p.id!),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            DetallePlantaScreen(store: store, id: p.id!),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => AgregarPlantaScreen(store: store),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Agregar planta'),
        ),
        const SizedBox(height: 28),
        Text(
          'Próximos cuidados',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (store.recordatorios.isEmpty)
          const Vacio(
            titulo: 'Todo en calma',
            texto: 'Aquí aparecerán tus próximas revisiones.',
          ),
        ...store.recordatorios
            .take(4)
            .map(
              (r) => CuidadoCard(
                titulo: store.plantas
                    .firstWhere((p) => p.id == r.plantaId)
                    .nombre,
                subtitulo: '${r.tipo.tarea} · ${fechaCorta(r.fecha)}',
                tipo: r.tipo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DetallePlantaScreen(store: store, id: r.plantaId),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 20),
        Text(
          'Cada cuidado cuenta',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            stat(
              '${store.cuidados.where((c) => !c.fecha.isBefore(week)).length}',
              'Cuidados esta semana',
            ),
          ],
        ),
        if (most.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Más acompañada: ${store.plantas.firstWhere((p) => p.id == most.first.key).nombre} · ${most.first.value} registros',
            ),
          ),
        const SizedBox(height: 20),
        NotificationCard(store: store),
        if (store.aviso != null) Text(store.aviso!),
        const SizedBox(height: 16),
        const Text(
          'Plantas hoy, un mañana más verde.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'serif', fontSize: 23, color: verde),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget stat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
          color: verde,
        ),
      ),
      Text(label),
    ],
  );
}
