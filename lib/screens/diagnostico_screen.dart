import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/diagnostico.dart';
import '../services/app_store.dart';
import '../widgets/planta_card.dart';
import '../widgets/cuidado_card.dart';

class DiagnosticoScreen extends StatefulWidget {
  final AppStore store;
  const DiagnosticoScreen({super.key, required this.store});
  @override
  State<DiagnosticoScreen> createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen> {
  int step = 0;
  int? plantId;
  final selected = <String>{};
  final answers = <String, String>{};
  List<PosibleCausa> result = [];
  bool busy = false;
  final questions = <String, (String, List<String>)>{
    'humedad': ('¿Cómo está el sustrato?', ['Seca', 'Húmeda', 'No sé']),
    'drenaje': ('¿El agua puede drenar?', ['Sí', 'No', 'No sé']),
    'luz': (
      '¿Qué luz recibe?',
      ['Sol directo', 'Luz indirecta', 'Semisombra', 'Sombra'],
    ),
    'riego': ('¿La regaste en los últimos dos días?', ['Sí', 'No', 'No sé']),
    'insectos': ('¿Ves insectos o telarañas?', ['Sí', 'No', 'No sé']),
  };
  Future<void> next() async {
    if (step < 2) {
      setState(() => step++);
      return;
    }
    setState(() => busy = true);
    await ejecutar(context, () async {
      final results = diagnosticar(selected, answers);
      await widget.store.database.diagnosis(plantId!, {
        'sintomas': selected.toList(),
        'respuestas': answers,
        'causas': results.map((r) => r.toMap()).toList(),
      });
      await widget.store.reload();
      if (mounted) {
        setState(() {
          result = results;
          step = 3;
        });
      }
    });
    if (mounted) {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store.plantas.isEmpty) {
      return const Center(
        child: Vacio(
          titulo: 'Conozcamos primero tu planta',
          texto: 'Agrega una planta desde Inicio para recibir orientación y guardar sus resultados.',
        ),
      );
    }
    final canContinue = step == 0
        ? plantId != null
        : step == 1
        ? selected.isNotEmpty
        : answers.length == questions.length;
    return ListView(
      key: ValueKey(step),
      padding: const EdgeInsets.all(20),
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Florece',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 34,
                  color: verde,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.offline_pin_outlined, color: verde),
            SizedBox(width: 6),
            Text('Sin conexión'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '¿Qué le pasa a tu planta?',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        Text('Paso ${step + 1} de 4'),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (step + 1) / 4,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 24),
        Text(
          [
            'Selecciona tu planta',
            '¿Qué síntomas observas?',
            'Conozcamos sus condiciones',
            'Orientación para tu planta',
          ][step],
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        if (step == 0)
          ...widget.store.plantas.map(
            (p) => Card(
              color: plantId == p.id ? salvia : null,
              child: ListTile(
                leading: SizedBox(
                  width: 65,
                  child: PlantaImagen(
                    especie: p.especie,
                    foto: p.foto,
                    height: 70,
                  ),
                ),
                title: Text(p.nombre),
                subtitle: Text(widget.store.especie(p.especie).nombre),
                trailing: Icon(
                  plantId == p.id ? Icons.check_circle : Icons.circle_outlined,
                  color: verde,
                ),
                onTap: () => setState(() => plantId = p.id),
              ),
            ),
          ),
        if (step == 1)
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth < 360 ? 2 : 3;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: sintomas.asMap().entries.map((entry) {
                  final s = entry.value;
                  final active = selected.contains(s);
                  return SizedBox(
                    width: (c.maxWidth - (cols - 1) * 10) / cols,
                    child: Semantics(
                      selected: active,
                      child: Card(
                        color: active ? salvia : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: active ? verde : const Color(0xFFE5DFD2),
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(
                            () => active ? selected.remove(s) : selected.add(s),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 8,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  [
                                    Icons.eco,
                                    Icons.grain,
                                    Icons.grass,
                                    Icons.spa,
                                    Icons.pest_control,
                                    Icons.local_florist,
                                    Icons.eco_outlined,
                                    Icons.trending_down,
                                    Icons.blur_on,
                                    Icons.yard,
                                  ][entry.key],
                                  size: 45,
                                  color: active
                                      ? verde
                                      : const Color(0xFF8D9E61),
                                ),
                                const SizedBox(height: 12),
                                Text(s, textAlign: TextAlign.center),
                                if (active)
                                  const Icon(
                                    Icons.check_circle,
                                    color: verde,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        if (step == 2)
          ...questions.entries.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: DropdownButtonFormField<String>(
                initialValue: answers[q.key],
                isExpanded: true,
                decoration: InputDecoration(labelText: q.value.$1),
                items: q.value.$2
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => answers[q.key] = v!),
              ),
            ),
          ),
        if (step == 3)
          ...result.map(
            (r) => Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POSIBLE CAUSA',
                      style: TextStyle(
                        color: verde,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.nombre,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(r.consejo),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: salvia,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            step == 3
                ? 'Esta orientación no es un diagnóstico exacto y no sustituye la valoración de una persona especialista. Resultado guardado en tu dispositivo.'
                : 'Te orientaremos con posibles causas. No analizamos fotografías.',
          ),
        ),
        const SizedBox(height: 20),
        if (step < 3)
          FilledButton.icon(
            onPressed: canContinue && !busy ? next : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(busy ? 'Guardando…' : 'Continuar'),
          ),
        if (step > 0 && step < 3)
          TextButton(
            onPressed: busy ? null : () => setState(() => step--),
            child: const Text('Atrás'),
          ),
        if (step == 3)
          FilledButton(
            onPressed: () => setState(() {
              step = 0;
              plantId = null;
              selected.clear();
              answers.clear();
              result = [];
            }),
            child: const Text('Nueva consulta'),
          ),
        if (step == 0) ...[
          const SizedBox(height: 30),
          Text(
            'Consultas anteriores',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.store.diagnosticos.isEmpty)
            const Vacio(
              titulo: 'Aún no hay consultas',
              texto: 'Tus orientaciones se guardarán aquí.',
            ),
          ...widget.store.diagnosticos.map((d) {
            final data =
                jsonDecode(d['datos'] as String) as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(
                  widget.store.plantas
                      .firstWhere((p) => p.id == d['plantaId'])
                      .nombre,
                ),
                subtitle: Text(
                  fechaCorta(DateTime.parse(d['fecha'] as String)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Orientación guardada'),
                    content: SingleChildScrollView(
                      child: Text(
                        '${(data['sintomas'] as List).join(', ')}\n\n${(data['causas'] as List).map((v) => 'Posible causa: ${v['nombre']}\n${v['consejo']}').join('\n\n')}\n\nNo sustituye una valoración especialista.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
