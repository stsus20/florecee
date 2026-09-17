import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cuidado.dart';
import 'entrada_suave.dart';

Color colorCuidado(TipoCuidado t) => switch (t) {
  TipoCuidado.riego => const Color(0xFF579DD0),
  TipoCuidado.abono => const Color(0xFFD6A23D),
  TipoCuidado.revision => const Color(0xFF8A659B),
  TipoCuidado.humeda => const Color(0xFF6F8B58),
  TipoCuidado.trasplante => const Color(0xFFC4866D),
};
IconData iconCuidado(TipoCuidado t) => switch (t) {
  TipoCuidado.riego => Icons.water_drop_outlined,
  TipoCuidado.abono => Icons.eco_outlined,
  TipoCuidado.revision => Icons.check_circle_outline,
  TipoCuidado.humeda => Icons.grass,
  TipoCuidado.trasplante => Icons.yard_outlined,
};

class CuidadoCard extends StatelessWidget {
  final String titulo, subtitulo;
  final TipoCuidado tipo;
  final VoidCallback? onTap;
  const CuidadoCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.tipo,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => EntradaSuave(
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorCuidado(tipo).withValues(alpha: .15),
          child: Icon(iconCuidado(tipo), color: colorCuidado(tipo)),
        ),
        title: Text(titulo),
        subtitle: Text(subtitulo),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    ),
  );
}

String fechaCorta(DateTime d) => DateFormat('d MMM yyyy', 'es').format(d);

class Vacio extends StatelessWidget {
  final String titulo, texto;
  final Widget? accion;
  const Vacio({
    super.key,
    required this.titulo,
    required this.texto,
    this.accion,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Column(
      children: [
        const Icon(Icons.spa_outlined, size: 58, color: Color(0xFF63A53E)),
        const SizedBox(height: 16),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(texto, textAlign: TextAlign.center),
        if (accion != null)
          Padding(padding: const EdgeInsets.only(top: 18), child: accion),
      ],
    ),
  );
}

Future<void> ejecutar(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el cambio. Inténtalo de nuevo.'),
        ),
      );
    }
  }
}
