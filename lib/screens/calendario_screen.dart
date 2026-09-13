import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_store.dart';
import '../models/cuidado.dart';
import '../widgets/planta_card.dart';
import '../widgets/cuidado_card.dart';
import 'detalle_planta_screen.dart';

class CalendarioScreen extends StatefulWidget {
  final AppStore store;
  const CalendarioScreen({super.key, required this.store});
  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime selected = dia(DateTime.now());
  late DateTime month = DateTime(selected.year, selected.month);
  TipoCuidado? filter;
  bool accepts(TipoCuidado t) =>
      filter == null ||
      t == filter ||
      (filter == TipoCuidado.revision && t == TipoCuidado.humeda);
  void move(int delta) => setState(() {
    month = DateTime(month.year, month.month + delta);
    selected = month;
  });
  @override
  Widget build(BuildContext context) {
    final start = month.subtract(Duration(days: month.weekday - 1));
    final count =
        ((month.weekday - 1 + DateTime(month.year, month.month + 1, 0).day) / 7)
            .ceil() *
        7;
    final reminders = widget.store.recordatorios
        .where((r) => mismoDia(r.fecha, selected) && accepts(r.tipo))
        .toList();
    final completed = widget.store.cuidados
        .where((r) => mismoDia(r.fecha, selected) && accepts(r.tipo))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Florece ❧',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 36,
            color: verde,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text('Pequeños cuidados, grandes vidas'),
        const SizedBox(height: 24),
        Text(
          'Calendario de cuidados',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Mes anterior',
                      onPressed: () => move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy', 'es').format(month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mes siguiente',
                      onPressed: () => move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: count,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: 57,
                  ),
                  itemBuilder: (context, i) {
                    final d = DateTime(start.year, start.month, start.day + i);
                    final markers = <TipoCuidado>{
                      ...widget.store.recordatorios
                          .where((r) => mismoDia(r.fecha, d) && accepts(r.tipo))
                          .map((r) => r.tipo),
                      ...widget.store.cuidados
                          .where((r) => mismoDia(r.fecha, d) && accepts(r.tipo))
                          .map((r) => r.tipo),
                    };
                    return Semantics(
                      label: fechaCorta(d),
                      selected: mismoDia(d, selected),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => selected = d),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: mismoDia(d, selected)
                                    ? verde
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${d.day}',
                                style: TextStyle(
                                  color: mismoDia(d, selected)
                                      ? Colors.white
                                      : d.month == month.month
                                      ? const Color(0xFF183B2C)
                                      : Colors.grey,
                                  fontWeight: mismoDia(d, DateTime.now())
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: markers
                                  .take(4)
                                  .map(
                                    (t) => Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorCuidado(t),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final item in <TipoCuidado?, String>{
              null: 'Todos',
              TipoCuidado.riego: 'Riego',
              TipoCuidado.abono: 'Abono',
              TipoCuidado.revision: 'Revisión',
            }.entries)
              ChoiceChip(
                label: Text(item.value),
                selected: filter == item.key,
                onSelected: (_) => setState(() => filter = item.key),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                mismoDia(selected, DateTime.now())
                    ? 'Hoy'
                    : fechaCorta(selected),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                selected = dia(DateTime.now());
                month = DateTime(selected.year, selected.month);
              }),
              child: const Text('Ir a hoy'),
            ),
          ],
        ),
        Text(DateFormat('EEEE, d MMMM yyyy', 'es').format(selected)),
        if (reminders.isEmpty && completed.isEmpty)
          const Vacio(
            titulo: 'Un día tranquilo',
            texto: 'No hay actividades para esta fecha y filtro. Puedes programar cuidados desde la ficha de una planta.',
          ),
        ...reminders.map(
          (r) => CuidadoCard(
            titulo: widget.store.plantas
                .firstWhere((p) => p.id == r.plantaId)
                .nombre,
            subtitulo: r.tipo.tarea,
            tipo: r.tipo,
            onTap: () => open(r.plantaId),
          ),
        ),
        if (completed.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('Cuidados completados'),
          ),
        ...completed.map(
          (r) => CuidadoCard(
            titulo: widget.store.plantas
                .firstWhere((p) => p.id == r.plantaId)
                .nombre,
            subtitulo: '✓ ${r.tipo.label}',
            tipo: r.tipo,
            onTap: () => open(r.plantaId),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void open(int id) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => DetallePlantaScreen(store: widget.store, id: id),
    ),
  );
}
