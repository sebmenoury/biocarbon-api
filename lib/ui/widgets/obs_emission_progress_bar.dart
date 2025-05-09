import 'package:flutter/material.dart';
import 'dart:math';

class EmissionProgressBar extends StatelessWidget {
  final double valeurActuelle;
  final double cible2035;
  final double cible2050;

  const EmissionProgressBar({
    super.key,
    required this.valeurActuelle,
    required this.cible2035,
    required this.cible2050,
  });

  @override
  Widget build(BuildContext context) {
    final double maxValeur = max(valeurActuelle, max(cible2035, cible2050));
    final double maxBar = (maxValeur * 1.2).ceilToDouble();
    final double percent2035 = (valeurActuelle / cible2035 * 100).roundToDouble();

    final Color couleurActuelle = valeurActuelle > cible2035
        ? Colors.red
        : (valeurActuelle > cible2050 ? Colors.orange : Colors.green);

    final double barreHauteur = 12;

    double getPosition(double valeur) => (valeur / maxBar).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mesure par rapport aux cibles",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Repères au-dessus
        LayoutBuilder(builder: (context, constraints) {
          double barWidth = constraints.maxWidth;

          Widget buildMarker(String label, double valeur, Color color) {
            return Positioned(
              left: barWidth * getPosition(valeur) - 12,
              top: 0,
              child: Column(
                children: [
                  Text(label, style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 2),
                  Icon(Icons.location_pin, size: 16, color: color),
                  const SizedBox(height: 2),
                  Text("${valeur.round()} kg", style: const TextStyle(fontSize: 10)),
                ],
              ),
            );
          }

          return SizedBox(
            height: 60,
            child: Stack(
              children: [
                buildMarker("2050", cible2050, Colors.green),
                buildMarker("2035", cible2035, Colors.orange),
                // ❌ Pas de repère pour "valeur actuelle" ici
              ],
            ),
          );
        }),

        // Barre de progression
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: barreHauteur,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(barreHauteur / 2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: getPosition(valeurActuelle),
              child: Container(
                height: barreHauteur,
                decoration: BoxDecoration(
                  color: couleurActuelle,
                  borderRadius: BorderRadius.circular(barreHauteur / 2),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Valeur actuelle sous la barre avec icône
        LayoutBuilder(builder: (context, constraints) {
        double barWidth = constraints.maxWidth;
        double position = barWidth * getPosition(valeurActuelle);

        return SizedBox(
            height: 50,
            child: Stack(
            children: [
                Transform.translate(
                offset: Offset(position - 40, 0), // ajuste ici si nécessaire
                child: Column(
                    children: [
                    const Text("Valeur actuelle", style: TextStyle(fontSize: 10)),
                    Icon(Icons.location_pin, size: 16, color: couleurActuelle),
                    Text("${valeurActuelle.round()} kg", style: const TextStyle(fontSize: 10)),
                    ],
                ),
                ),
            ],
            ),
        );
        }),



        const SizedBox(height: 4),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "${percent2035.round()} % / 2035",
            style: TextStyle(
              fontSize: 8,
              color: couleurActuelle,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
