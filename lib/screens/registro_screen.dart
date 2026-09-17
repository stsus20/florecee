import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/planta.dart';
import '../models/registro.dart';
import '../services/app_store.dart';
import '../widgets/planta_card.dart';

class RegistroScreen extends StatefulWidget {
  final AppStore store;
  final Planta planta;
  const RegistroScreen({super.key, required this.store, required this.planta});
  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final form = GlobalKey<FormState>();
  final hojas = TextEditingController(),
      porcentaje = TextEditingController(),
      altura = TextEditingController(),
      anchura = TextEditingController();
  bool? amarillas;
  String? foto;
  bool busy = false;
  final imported = <String>{};
  @override
  void initState() {
    super.initState();
    recover();
  }

  Future<void> recover() async {
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.files?.isNotEmpty ?? false) {
        await accept(response.files!.first);
      }
    } catch (_) {}
  }

  Future<void> accept(XFile f) async {
    final permanent = await widget.store.importPhoto(f);
    imported.add(permanent);
    if (mounted) {
      setState(() => foto = permanent);
    } else {
      await widget.store.deletePhoto(permanent);
    }
  }

  Future<void> pick(ImageSource source) async {
    setState(() => busy = true);
    try {
      final f = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (f != null) {
        await accept(f);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo cargar la fotografía. Revisa los permisos e inténtalo de nuevo.',
            ),
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
  void dispose() {
    for (final f in imported) {
      widget.store.deletePhoto(f).catchError((Object _) {});
    }
    hojas.dispose();
    porcentaje.dispose();
    altura.dispose();
    anchura.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) {
      return;
    }
    setState(() => busy = true);
    try {
      await widget.store.addRegistro(
        planta: widget.planta,
        hojas: int.parse(hojas.text.trim()),
        amarillas: amarillas!,
        porcentaje: amarillas! ? int.parse(porcentaje.text.trim()) : 0,
        altura: parseMedida(altura.text)!,
        anchura: parseMedida(anchura.text)!,
        foto: foto!,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro y PDF guardados en el historial.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el registro y su PDF. Revisa el espacio disponible e inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Widget number(
    TextEditingController c,
    String label, {
    bool decimal = false,
  }) => TextFormField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    decoration: InputDecoration(
      labelText: label,
      suffixText: decimal ? 'cm' : null,
      errorMaxLines: 2,
    ),
    validator: (v) {
      final n = parseMedida(v ?? '');
      if (n == null ||
          !n.isFinite ||
          n < 0 ||
          (decimal && n == 0) ||
          (!decimal && int.tryParse((v ?? '').trim()) == null) ||
          n > 100000) {
        return decimal
            ? 'Indica una medida mayor que 0'
            : 'Indica un número entero entre 0 y 100000';
      }
      return null;
    },
  );
  Widget section(String step, String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE3E9D8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: salvia,
              child: Text(
                step,
                style: const TextStyle(
                  color: verde,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Form(
        key: form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AbsorbPointer(
            absorbing: busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Así crece ${widget.planta.nombre}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Observa, mide y guarda este momento. Cada registro tendrá su propia foto y un informe PDF.',
                ),
                const SizedBox(height: 24),
                section('1', 'Sus hojas', [
                  number(hojas, '¿Cuántas hojas tiene?'),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<bool>(
                    initialValue: amarillas,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '¿Están amarillas?',
                    ),
                    items: const [
                      DropdownMenuItem(value: false, child: Text('No')),
                      DropdownMenuItem(value: true, child: Text('Sí')),
                    ],
                    validator: (v) => v == null
                        ? 'Selecciona Sí o No'
                        : v && int.tryParse(hojas.text.trim()) == 0
                        ? 'Si no tiene hojas, selecciona No'
                        : null,
                    onChanged: (v) => setState(() => amarillas = v),
                  ),
                  if (amarillas == true) ...[
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: porcentaje,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '¿Qué tanto?',
                        suffixText: '%',
                        helperText:
                            'Porcentaje aproximado de hojas amarillas (1–100).',
                        helperMaxLines: 2,
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return n == null || n < 1 || n > 100
                            ? 'Indica un porcentaje entre 1 y 100'
                            : null;
                      },
                    ),
                  ],
                ]),
                section('2', 'El tallo', [
                  number(altura, 'Altura del tallo', decimal: true),
                  const SizedBox(height: 18),
                  number(anchura, 'Anchura del tallo', decimal: true),
                  const SizedBox(height: 10),
                  const Text(
                    'Mide siempre desde el mismo punto para comparar su crecimiento.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ]),
                section('3', 'Una foto de este momento', [
                  if (foto != null)
                    PlantaImagen(
                      especie: widget.planta.especie,
                      foto: foto,
                      height: 190,
                    ),
                  FormField<String>(
                    validator: (_) => foto == null
                        ? 'Agrega una fotografía para el registro'
                        : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => pick(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Tomar foto'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => pick(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Galería'),
                            ),
                            if (widget.planta.foto != null)
                              TextButton(
                                onPressed: () =>
                                    setState(() => foto = widget.planta.foto),
                                child: const Text('Usar foto de la planta'),
                              ),
                          ],
                        ),
                        if (state.hasError)
                          Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
                FilledButton.icon(
                  onPressed: busy ? null : save,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.note_add_outlined),
                  label: Text(
                    busy ? 'Guardando registro…' : 'Guardar registro y PDF',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
