import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/racha.dart';
import 'planta_card.dart';

class RachaCard extends StatelessWidget {
  final int dias;
  const RachaCard({super.key, required this.dias});
  @override
  Widget build(BuildContext context) {
    final growth = CrecimientoRacha(dias);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F4C9), Color(0xFFE6F2C3), Color(0xFFD1EBC8)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFCADFA2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x102D663F),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF9A7015),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TU JARDÍN DE CONSTANCIA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.4,
                    color: verde,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dias',
                    style: const TextStyle(
                      fontSize: 58,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: verde,
                    ),
                  ),
                  Text(
                    dias == 1 ? 'día de racha' : 'días de racha',
                    style: const TextStyle(
                      color: verde,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    growth.nombre,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    growth.siguiente,
                    style: const TextStyle(
                      color: Color(0xFF475B36),
                      height: 1.4,
                    ),
                  ),
                ],
              );
              final art = Semantics(
                label: 'Margarita de racha: ${growth.etapa.name}, $dias días',
                child: RepaintBoundary(
                  child: SizedBox(
                    height: 200,
                    width: c.maxWidth < 360 ? 138 : 180,
                    child: MargaritaRacha(dias: dias),
                  ),
                ),
              );
              if (c.maxWidth < 280) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: art),
                    info,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 8),
                  art,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: growth.progreso),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: .65),
                color: verde,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              milestone(
                context,
                '1–10 · Brote',
                growth.etapa == EtapaRacha.brote,
              ),
              milestone(
                context,
                '11–20 · Tallo',
                growth.etapa == EtapaRacha.tallo,
              ),
              milestone(
                context,
                '21–30 · Flor',
                growth.etapa == EtapaRacha.flor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Una revisión también cuenta. Cuida según lo que tu planta necesite.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF526545),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget milestone(BuildContext context, String label, bool active) =>
      AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? verde : Colors.white.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : verde,
          ),
        ),
      );
}

class MargaritaRacha extends StatelessWidget {
  final int dias;
  const MargaritaRacha({super.key, required this.dias});
  @override
  Widget build(BuildContext context) {
    final target = CrecimientoRacha(dias).diasVisuales.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      return CustomPaint(painter: MargaritaPainter(dias: target));
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) =>
          CustomPaint(painter: MargaritaPainter(dias: value)),
    );
  }
}

class MargaritaPainter extends CustomPainter {
  final double dias;
  const MargaritaPainter({required this.dias});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height - 18);
    final scale = math.min(size.width / 180, size.height / 200);
    canvas.scale(scale);
    final p = Paint()..isAntiAlias = true;
    p.color = const Color(0xFFFFFCDF);
    canvas.drawCircle(const Offset(0, -91), 76, p);
    p.color = const Color(0xFFA2C58D).withValues(alpha: .3);
    canvas.drawOval(const Rect.fromLTWH(-58, -4, 116, 13), p);
    p.color = const Color(0xFFB78750);
    canvas.drawOval(const Rect.fromLTWH(-28, -1, 56, 6), p);
    final d = dias.clamp(0, 30).toDouble();
    if (d < .5) {
      canvas.save();
      canvas.rotate(-.35);
      p.color = const Color(0xFFAC7547);
      canvas.drawOval(const Rect.fromLTWH(-7, -11, 14, 10), p);
      p
        ..color = const Color(0xFFE6BD75)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(-3, -8), const Offset(3, -4), p);
      canvas.restore();
    } else {
      final height = d <= 10
          ? 25 + d * 2.5
          : d <= 20
          ? 50 + (d - 10) * 6
          : 110 + (d - 20) * 1.3;
      final sway = math.sin(d / 30 * math.pi) * 3;
      final top = Offset(sway, -height);
      p
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5
        ..color = verde;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(-6, -height * .4, 7, -height * .75, top.dx, top.dy),
        p,
      );
      p.style = PaintingStyle.fill;
      leaf(canvas, Offset(0, -height * .44), -1, math.min(1, .5 + d / 20));
      leaf(canvas, Offset(1, -height * .67), 1, math.min(1, .4 + d / 20));
      if (d > 10) {
        leaf(canvas, Offset(-1, -height * .24), 1, math.min(1, (d - 10) / 7));
      }
      if (d > 20) {
        final bloom = .5 + (d - 21).clamp(0, 9) / 18;
        canvas.save();
        canvas.translate(top.dx, top.dy);
        canvas.scale(bloom);
        for (var i = 0; i < 12; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 6);
          p.color = const Color(0xFFD4DDB4);
          canvas.drawOval(const Rect.fromLTWH(-8, -41, 18, 35), p);
          p.color = i.isEven ? Colors.white : const Color(0xFFFFFBEA);
          canvas.drawOval(const Rect.fromLTWH(-8, -43, 16, 34), p);
          canvas.restore();
        }
        p.color = const Color(0xFFD69A17);
        canvas.drawCircle(const Offset(0, 1), 15, p);
        p.color = const Color(0xFFFFCB45);
        canvas.drawCircle(const Offset(0, -1), 13, p);
        for (var i = 0; i < 9; i++) {
          final a = i * 2.4;
          p.color = const Color(0xFFE8A719);
          canvas.drawCircle(Offset(math.cos(a) * 8, math.sin(a) * 7), 1.2, p);
        }
        p.color = const Color(0xFFFFE698);
        canvas.drawCircle(const Offset(-4, -5), 3, p);
        canvas.restore();
      } else if (d > 15) {
        p.color = const Color(0xFF86B64D);
        canvas.drawOval(
          Rect.fromCenter(center: top, width: 11 + (d - 15), height: 18),
          p,
        );
      }
    }
    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFF1BA39);
    for (final spot in [const Offset(-62, -118), const Offset(58, -76)]) {
      final path = Path()
        ..moveTo(spot.dx, spot.dy - 5)
        ..lineTo(spot.dx + 2, spot.dy - 1)
        ..lineTo(spot.dx + 5, spot.dy)
        ..lineTo(spot.dx + 2, spot.dy + 1)
        ..lineTo(spot.dx, spot.dy + 5)
        ..lineTo(spot.dx - 2, spot.dy + 1)
        ..lineTo(spot.dx - 5, spot.dy)
        ..lineTo(spot.dx - 2, spot.dy - 1)
        ..close();
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  void leaf(Canvas c, Offset origin, double side, double growth) {
    c.save();
    c.translate(origin.dx, origin.dy);
    c.scale(side * growth, growth);
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(12, -31, 32, -29, 39, -34)
      ..cubicTo(40, -6, 19, 5, 0, 0);
    final p = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        colors: [Color(0xFF299356), Color(0xFF88BF49)],
      ).createShader(const Rect.fromLTWH(0, -34, 39, 34));
    c.drawPath(path, p);
    p
      ..shader = null
      ..color = const Color(0xFFC2DD77)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    c.drawPath(
      Path()
        ..moveTo(3, -2)
        ..quadraticBezierTo(20, -12, 34, -27),
      p,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(MargaritaPainter old) => old.dias != dias;
}
