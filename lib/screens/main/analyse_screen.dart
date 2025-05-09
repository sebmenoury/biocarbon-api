import 'package:flutter/material.dart';
import 'package:carbone_web/ui/layout/base_screen.dart';
import 'package:carbone_web/ui/layout/custom_card.dart';
import '../../ui/widgets/dashboard_gauge.dart';

class AnalyseScreen extends StatelessWidget {
  const AnalyseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: "Analyse des Données",
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DashboardGauge(valeur: 7200),
              SizedBox(height: 12),
              Text(
                "Niveau d'émission carbone",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 1),
              Text(
                "Données annuelles en kg CO₂e / personne",
                style: TextStyle(fontSize: 8, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const CustomCard(
          child: Text(
            "Déclaration des équipements et usages",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const CustomCard(
          child: Text(
            "Habitat, Alimentation, Équipements…",
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
