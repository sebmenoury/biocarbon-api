// Fichier : lib/ui/widgets/dashboard_donut.dart

import 'package:flutter/material.dart';
import 'dart:math';

class DashboardDonut extends StatelessWidget {
  final double valeur;
  final double seuil2050;
  final double seuil2035;
  final double seuil2017;

  const DashboardDonut({
    super.key,
    required this.valeur,
    this.seuil2050 = 2000,
    this.seuil2035 = 5700,
    this.seuil2017 = 9500,
  });

  @override
  Widget build(BuildContext context) {
    final double maxValue = valeur > 10000 ? valeur * 1.1 : 10000;
    final double angle2050 = (seuil2050 / maxValue) * 360;
    final double angle2035 = (seuil2035 / maxValue) * 360;
    final double angle2017 = (seuil2017 / maxValue) * 360;
    final double angleValeur = (valeur / maxValue) * 360;

    final List<_ArcSegment> segments = [
      _ArcSegment(
        angle: angle2050,
        color: const Color(0xFF4CAF50),
        label: 'Objectif\n2050',
        valeur: '2 t',
      ),
      _ArcSegment(
        angle: angle2035 - angle2050,
        color: const Color(0xFFFF9800),
        label: 'Objectif\n2035',
        valeur: '5,7 t',
      ),
      _ArcSegment(
        angle: angle2017 - angle2035,
        color: const Color(0xFFF44336),
        label: 'Niveau\n2017',
        valeur: '9,5 t',
      ),
      _ArcSegment(angle: 360 - angle2017, color: const Color(0xFFB71C1C)),
    ];

    return CustomPaint(
      size: const Size(240, 240),
      painter: _DonutPainter(
        segments: segments,
        angleValeur: angleValeur,
        valeurAffichee: valeur / 1000,
      ),
    );
  }
}

class _ArcSegment {
  final double angle;
  final Color color;
  final String? label;
  final String? valeur;
  const _ArcSegment({
    required this.angle,
    required this.color,
    this.label,
    this.valeur,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_ArcSegment> segments;
  final double angleValeur;
  final double valeurAffichee;

  _DonutPainter({
    required this.segments,
    required this.angleValeur,
    required this.valeurAffichee,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final arcWidth = 28.0;
    final innerRadius = radius - arcWidth;

    double startAngle = -pi / 2;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweepAngle = seg.angle * pi / 180;
      final paint =
          Paint()
            ..color = seg.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = arcWidth
            ..strokeCap = StrokeCap.butt;

      final arcRect = Rect.fromCircle(
        center: center,
        radius: radius - arcWidth / 2,
      );
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, paint);

      // Trait blanc entre les arcs (sauf dernier)
      if (i < segments.length - 1) {
        final separatorPaint =
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = arcWidth + 2;
        canvas.drawArc(
          arcRect,
          startAngle + sweepAngle - 0.01,
          0.02,
          false,
          separatorPaint,
        );
      }

      if (seg.label != null && seg.valeur != null) {
        final angleEnd = startAngle + sweepAngle;
        final angleRad = angleEnd;

        // Texte valeur à l'intérieur
        final offsetValue = Offset(
          center.dx + innerRadius * 0.85 * cos(angleRad),
          center.dy + innerRadius * 0.85 * sin(angleRad),
        );
        textPainter.text = TextSpan(
          text: seg.valeur!,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        );
        textPainter.layout();
        canvas.save();
        canvas.translate(
          offsetValue.dx - textPainter.width / 2,
          offsetValue.dy - textPainter.height / 2,
        );
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();

        // Légende à l'extérieur
        final offsetLabel = Offset(
          center.dx + (radius + 6) * cos(angleRad),
          center.dy + (radius + 6) * sin(angleRad),
        );
        textPainter.text = TextSpan(
          text: seg.label!,
          style: const TextStyle(fontSize: 9, color: Colors.black, height: 1.1),
        );
        textPainter.layout();
        canvas.save();
        canvas.translate(
          offsetLabel.dx - textPainter.width / 2,
          offsetLabel.dy - textPainter.height / 2,
        );
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }

      startAngle += sweepAngle;
    }

    // Marqueur noir
    final angleRad = (angleValeur - 90) * pi / 180;
    final pointR = innerRadius + arcWidth / 2;
    final marker = Offset(
      center.dx + pointR * cos(angleRad),
      center.dy + pointR * sin(angleRad),
    );
    canvas.drawCircle(marker, 4, Paint()..color = Colors.black);

    // Texte central
    textPainter.text = TextSpan(
      text: valeurAffichee.toStringAsFixed(1),
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - 12),
    );

    textPainter.text = const TextSpan(
      text: 't CO₂e',
      style: TextStyle(fontSize: 12, color: Colors.black),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
