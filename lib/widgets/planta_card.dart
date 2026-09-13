import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/planta.dart';

const verde = Color(0xFF365F45),
    crema = Color(0xFFFAF7F0),
    salvia = Color(0xFFE8EEDF);

class PlantaImagen extends StatelessWidget {
  final String especie;
  final String? foto;
  final double height;
  const PlantaImagen({
    super.key,
    required this.especie,
    this.foto,
    this.height = 180,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: foto != null
          ? Image.file(
              File(foto!),
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => art,
            )
          : art,
    ),
  );
  Widget get art => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF2E7D8), salvia],
      ),
    ),
    child: CustomPaint(painter: BotanicaPainter(especie)),
  );
}

class BotanicaPainter extends CustomPainter {
  final String especie;
  BotanicaPainter(this.especie);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height * .84);
    final scale = size.height / 210;
    canvas.scale(scale);
    final paint = Paint()..isAntiAlias = true;
    paint.color = const Color(0xFFD8CCB6);
    canvas.drawOval(const Rect.fromLTWH(-65, -3, 130, 16), paint);
    final cactus = especie == 'cactus' || especie == 'sansevieria';
    if (cactus) {
      paint.color = verde;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-27, -135, 54, 110),
          const Radius.circular(28),
        ),
        paint,
      );
      paint
        ..color = const Color(0xFFABC091)
        ..strokeWidth = 2;
      for (var x = -16; x <= 16; x += 16) {
        canvas.drawLine(
          Offset(x.toDouble(), -115),
          Offset(x.toDouble(), -30),
          paint,
        );
      }
    } else {
      for (var i = 0; i < 7; i++) {
        final x = (i - 3) * 16.0, y = -65.0 - (i % 3) * 29;
        paint
          ..color = verde
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(0, -25), Offset(x, y - 10), paint);
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate((i - 3) * .24);
        paint
          ..style = PaintingStyle.fill
          ..color = i.isEven ? const Color(0xFF6F915B) : verde;
        final leaf = Path()
          ..moveTo(0, 12)
          ..quadraticBezierTo(-35, -12, -8, -49)
          ..quadraticBezierTo(24, -32, 0, 12);
        canvas.drawPath(leaf, paint);
        paint
          ..color = const Color(0xFFABC091)
          ..strokeWidth = 1;
        canvas.drawLine(const Offset(0, 8), const Offset(-8, -42), paint);
        if ([
              'tulipan',
              'rosa',
              'geranio',
              'orquidea',
              'girasol',
            ].contains(especie) &&
            i % 2 == 0) {
          paint.color = especie == 'girasol'
              ? const Color(0xFFE4B349)
              : const Color(0xFFD99291);
          for (var j = 0; j < 5; j++) {
            final a = j * math.pi * 2 / 5;
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(math.cos(a) * 9, -47 + math.sin(a) * 8),
                width: 17,
                height: 26,
              ),
              paint,
            );
          }
        }
        canvas.restore();
      }
    }
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFBF8264);
    canvas.drawPath(
      Path()
        ..moveTo(-38, -35)
        ..lineTo(38, -35)
        ..lineTo(28, 7)
        ..lineTo(-28, 7)
        ..close(),
      paint,
    );
    paint.color = const Color(0xFFD39C7D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-42, -39, 84, 12),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BotanicaPainter old) => old.especie != especie;
}

class PlantaCard extends StatelessWidget {
  final Planta planta;
  final String cientifico, accion;
  final bool pendiente;
  final VoidCallback onTap;
  const PlantaCard({
    super.key,
    required this.planta,
    required this.cientifico,
    required this.accion,
    required this.pendiente,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlantaImagen(especie: planta.especie, foto: planta.foto),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planta.nombre,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  cientifico,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Chip(
                  avatar: Icon(
                    pendiente ? Icons.priority_high : Icons.eco,
                    size: 17,
                  ),
                  label: Text(pendiente ? 'Por revisar' : 'Al día'),
                  backgroundColor: pendiente ? const Color(0xFFF7DFD7) : salvia,
                ),
                const SizedBox(height: 8),
                Text(accion),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
