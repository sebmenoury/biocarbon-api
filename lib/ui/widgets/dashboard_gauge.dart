// Fichier : lib/ui/widgets/dashboard_gauge.dart

import 'package:flutter/material.dart';
import 'dart:math';

class DashboardGauge extends StatelessWidget {
  final double valeur;
  final double seuil2050;
  final double seuil2035;
  final double seuil2017;

  const DashboardGauge({
    super.key,
    required this.valeur,
    this.seuil2050 = 2000,
    this.seuil2035 = 5700,
    this.seuil2017 = 9500,
  });

  @override
  Widget build(BuildContext context) {
    final double maxValue = valeur > 10000 ? valeur * 1.1 : 10000;
    return CustomPaint(
      size: const Size(280, 160),
      painter: _GaugePainter(
        valeur: valeur,
        seuil2050: seuil2050,
        seuil2035: seuil2035,
        seuil2017: seuil2017,
        maxValue: maxValue,
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double valeur;
  final double seuil2050;
  final double seuil2035;
  final double seuil2017;
  final double maxValue;

  _GaugePainter({
    required this.valeur,
    required this.seuil2050,
    required this.seuil2035,
    required this.seuil2017,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    final arcWidth = 20.0;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth
          ..strokeCap = StrokeCap.butt;

    double start = pi;
    double angle2050 = pi * (seuil2050 / maxValue);
    double angle2035 = pi * ((seuil2035 - seuil2050) / maxValue);
    double angle2017 = pi * ((seuil2017 - seuil2035) / maxValue);
    double angleSurplus = pi * ((maxValue - seuil2017) / maxValue);

    final segments = [
      {"angle": angle2050, "color": const Color(0xFF4CAF50)},
      {"angle": angle2035, "color": const Color(0xFFFF9800)},
      {"angle": angle2017, "color": const Color(0xFFF44336)},
      {"angle": angleSurplus, "color": const Color(0xFFB71C1C)},
    ];

    for (var seg in segments) {
      paint.color = seg["color"] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        seg["angle"] as double,
        false,
        paint,
      );

      // Séparations blanches
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start - 0.005,
        0.01, // trait court
        false,
        Paint()
          ..color = Colors.white
          ..strokeWidth = arcWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );

      start += seg["angle"] as double;
    }

    // Aiguille triangulaire stylisée
    final valeurAngle = pi * (valeur / maxValue);
    final needleLength = radius - arcWidth - 4;
    final needlePaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;

    final baseWidth = 40.0;

    final needlePath =
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + baseWidth * cos(pi - valeurAngle + 0.06),
            center.dy - baseWidth * sin(pi - valeurAngle + 0.06),
          )
          ..lineTo(
            center.dx + needleLength * cos(pi - valeurAngle),
            center.dy - needleLength * sin(pi - valeurAngle),
          )
          ..lineTo(
            center.dx + baseWidth * cos(pi - valeurAngle - 0.06),
            center.dy - baseWidth * sin(pi - valeurAngle - 0.06),
          )
          ..close();

    canvas.drawPath(needlePath, needlePaint);

    // Texte au bout de l'aiguille
    final label = (valeur / 1000).toStringAsFixed(1);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      children: [TextSpan(text: '$label t\n')],
    );
    textPainter.layout();

    final labelOffset = Offset(
      center.dx +
          (needleLength - 4) * cos(pi - valeurAngle) -
          textPainter.width / 2,
      center.dy -
          (needleLength - 4) * sin(pi - valeurAngle) -
          textPainter.height / 2,
    );
    textPainter.paint(canvas, labelOffset);

    // Étiquettes seuils — positionnées sur l'arc
    final labelRadius = radius + arcWidth / 2 + 24;
    final labels = [
      {"value": seuil2050, "text": "Objectif\n2050\n2t"},
      {"value": seuil2035, "text": "Objectif\n2035\n5,7t"},
      {"value": seuil2017, "text": "Niveau\n2017\n9,5t"},
    ];

    for (var entry in labels) {
      final angle = pi * ((entry["value"] as double) / maxValue);
      final dx = center.dx + labelRadius * cos(pi - angle);
      final dy = center.dy - labelRadius * sin(pi - angle);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: entry["text"] as String,
          style: const TextStyle(fontSize: 10, color: Colors.black),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      canvas.save();
      canvas.translate(
        dx - labelPainter.width / 2,
        dy - labelPainter.height / 2,
      );
      labelPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
