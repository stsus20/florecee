import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/planta.dart';
import '../services/app_store.dart';
import '../widgets/planta_card.dart';
import '../widgets/cuidado_card.dart';

class AgregarPlantaScreen extends StatefulWidget {
  final AppStore store;
  final Planta? planta;
  final String? especieInicial;
  const AgregarPlantaScreen({
    super.key,
    required this.store,
    this.planta,
    this.especieInicial,
  });
  @override
  State<AgregarPlantaScreen> createState() => _AgregarPlantaScreenState();
}

class _AgregarPlantaScreenState extends State<AgregarPlantaScreen> {
  final form = GlobalKey<FormState>();
  late TextEditingController nombre, tamano, intervalo, notas, mito;
  String? tipoCuidado;
  late String especie, ubicacion, luz, recipiente;
  String? foto;
  late bool drenaje;
  late DateTime ultimo;
  bool saving = false;
  final importedPhotos = <String>{};
  @override
  void initState() {
    super.initState();
    final p = widget.planta;
    especie =
        p?.especie ?? widget.especieInicial ?? widget.store.catalogo.first.id;
    nombre = TextEditingController(text: p?.nombre ?? '');
    tamano = TextEditingController(text: p?.tamano ?? '20 cm');
    intervalo = TextEditingController(
      text: '${p?.intervalo ?? widget.store.especie(especie).intervalo}',
    );
    notas = TextEditingController(text: p?.notas ?? '');
    mito = TextEditingController(text: p?.mito ?? '');
    tipoCuidado = p?.tipoCuidado;
    ubicacion = p?.ubicacion ?? 'Interior';
    luz = p?.luz ?? 'Luz indirecta';
    recipiente = p?.recipiente ?? 'Maceta';
    foto = p?.foto;
    drenaje = p?.drenaje ?? true;
    ultimo = p?.ultimoRiego ?? DateTime.now();
    recover();
  }

  Future<void> recover() async {
    try {
      final lost = await ImagePicker().retrieveLostData();
      if (lost.files?.isNotEmpty ?? false) {
        final f = await widget.store.importPhoto(lost.files!.first);
        importedPhotos.add(f);
        if (mounted) {
          setState(() => foto = f);
        }
      }
    } catch (_) {
      /* Unsupported platforms have no lost Android picker data. */
    }
  }

  @override
  void dispose() {
    for (final file in importedPhotos) {
      widget.store.deletePhoto(file).catchError((Object _) {});
    }
    nombre.dispose();
    tamano.dispose();
    intervalo.dispose();
    notas.dispose();
    mito.dispose();
    super.dispose();
  }

  Future<void> pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 85,
      );
      if (file == null) {
        return;
      }
      final permanent = await widget.store.importPhoto(file);
      importedPhotos.add(permanent);
      if (mounted) {
        setState(() => foto = permanent);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir la fotografía. Revisa el permiso de cámara o elige otra imagen.',
            ),
          ),
        );
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) {
      return;
    }
    setState(() => saving = true);
    try {
      await widget.store.save(
        Planta(
          id: widget.planta?.id,
          nombre: nombre.text.trim(),
          especie: especie,
          foto: foto,
          ubicacion: ubicacion,
          luz: luz,
          recipiente: recipiente,
          tamano: tamano.text.trim(),
          drenaje: drenaje,
          ultimoRiego: ultimo,
          intervalo: int.parse(intervalo.text),
          notas: notas.text.trim(),
          tipoCuidado: tipoCuidado!,
          mito: tipoCuidado == 'mito' ? mito.text.trim() : '',
        ),
      );
      await widget.store.deletePhoto(widget.planta?.foto);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la planta. Inténtalo de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget drop(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: saving ? null : (v) => setState(() => change(v!)),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.planta == null ? 'Una nueva vida' : 'Editar planta'),
    ),
    body: Form(
      key: form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlantaImagen(especie: especie, foto: foto, height: 200),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: saving ? null : () => pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Cámara'),
                ),
                TextButton.icon(
                  onPressed: saving ? null : () => pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_outlined),
                  label: const Text('Galería'),
                ),
                if (foto != null)
                  TextButton(
                    onPressed: () => setState(() => foto = null),
                    child: const Text('Quitar'),
                  ),
              ],
            ),
            TextFormField(
              controller: nombre,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Nombre personalizado',
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: especie,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Especie'),
              items: widget.store.catalogo
                  .map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (v) => setState(() {
                      especie = v!;
                      intervalo.text = '${widget.store.especie(v).intervalo}';
                    }),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: salvia,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tu forma de cuidar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipoCuidado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de cuidado',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'mito', child: Text('Mito')),
                    ],
                    validator: (v) =>
                        v == null ? 'Selecciona un tipo de cuidado' : null,
                    onChanged: saving
                        ? null
                        : (v) => setState(() => tipoCuidado = v),
                  ),
                  if (tipoCuidado == 'mito') ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: mito,
                      maxLength: 300,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '¿Qué tipo de mito es?',
                        hintText:
                            'Describe con tus palabras el cuidado que realizas',
                      ),
                      validator: (v) =>
                          tipoCuidado == 'mito' && (v?.trim().isEmpty ?? true)
                          ? 'Describe el mito'
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            drop('Ubicación', ubicacion, [
              'Interior',
              'Exterior',
            ], (v) => ubicacion = v),
            drop('Luz disponible', luz, [
              'Sol directo',
              'Luz indirecta',
              'Semisombra',
              'Sombra',
            ], (v) => luz = v),
            drop('Cultivo', recipiente, [
              'Maceta',
              'Suelo directo',
            ], (v) => recipiente = v),
            TextFormField(
              controller: tamano,
              decoration: const InputDecoration(
                labelText: 'Tamaño aproximado de maceta o espacio',
              ),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Indica el tamaño aproximado'
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tiene drenaje'),
              value: drenaje,
              onChanged: (v) => setState(() => drenaje = v),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: ultimo,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  helpText: 'Último riego',
                );
                if (d != null) {
                  setState(() => ultimo = d);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text('Último riego: ${fechaCorta(ultimo)}'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: intervalo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Revisar humedad cada (días)',
                helperText: 'Revisa el sustrato antes de decidir regar.',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 1 || n > 90
                    ? 'Usa un número entre 1 y 90'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notas,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Notas opcionales'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Guardando…' : 'Guardar planta'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
