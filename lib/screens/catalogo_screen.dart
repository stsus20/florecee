import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../models/especie.dart';
import '../widgets/planta_card.dart';
import '../widgets/cuidado_card.dart';
import 'agregar_planta_screen.dart';

class CatalogoScreen extends StatefulWidget {
  final AppStore store;
  const CatalogoScreen({super.key, required this.store});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.store.catalogo
        .where(
          (s) => normalizar(
            '${s.nombre} ${s.cientifico} ${s.texto('otrosNombres')}',
          ).contains(normalizar(query)),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Text(
          'Descubre tu próxima planta',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.store.catalogo.length} especies · siempre disponibles sin conexión',
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (s) => setState(() => query = s),
          decoration: const InputDecoration(
            hintText: 'Buscar nombre o especie',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 18),
        if (list.isEmpty)
          const Vacio(
            titulo: 'Sin coincidencias',
            texto: 'Prueba con otro nombre.',
          ),
        ...list.map(
          (s) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: SizedBox(
                width: 65,
                child: PlantaImagen(especie: s.id, height: 75),
              ),
              title: Text(s.nombre),
              subtitle: Text(s.cientifico),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => FichaEspecie(store: widget.store, especie: s),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FichaEspecie extends StatelessWidget {
  final AppStore store;
  final Especie especie;
  const FichaEspecie({super.key, required this.store, required this.especie});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Catálogo · Florece')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PlantaImagen(especie: especie.id, height: 250),
        const SizedBox(height: 20),
        Text(especie.nombre, style: Theme.of(context).textTheme.headlineLarge),
        Text(especie.cientifico),
        const SizedBox(height: 16),
        Text(especie.texto('descripcion')),
        GuiaEspecie(especie: especie),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  AgregarPlantaScreen(store: store, especieInicial: especie.id),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Agregar esta planta'),
        ),
      ],
    ),
  );
}

class GuiaEspecie extends StatelessWidget {
  final Especie especie;
  const GuiaEspecie({super.key, required this.especie});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      Text(
        'Guía de cuidados',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      ...{
        'luz': '☀ Luz',
        'riego': '💧 Riego',
        'floracion': '✿ Floración',
        'fertilizacion': '❧ Fertilización',
        'maceta': 'Maceta',
        'sustrato': 'Sustrato',
        'suelo': 'Suelo directo',
        'drenaje': 'Drenaje',
        'consejos': 'Consejos',
        'problemas': 'Problemas frecuentes',
        if (especie.texto('familia').isNotEmpty) 'familia': 'Familia botánica',
        if (especie.texto('otrosNombres').isNotEmpty)
          'otrosNombres': 'También se conoce como',
        if (especie.texto('fuentes').isNotEmpty)
          'fuentes': 'Fuentes consultadas',
      }.entries.map(
        (e) => Card(
          child: ListTile(
            title: Text(e.value),
            subtitle: Text(especie.texto(e.key)),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Revisión inicial orientativa: cada ${especie.intervalo} días. Comprueba la humedad; riega según el sustrato, la estación y tu entorno. El intervalo no es una orden de riego.',
        ),
      ),
    ],
  );
}

String normalizar(String texto) {
  var result = texto.toLowerCase();
  for (final entry in {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
  }.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}
