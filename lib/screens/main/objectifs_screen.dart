import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/dashboard_gauge.dart';

class ObjectifsScreen extends StatelessWidget {
  const ObjectifsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Objectifs',
      children: [
        const CustomCard(child: Text('Suivi des objectifs 2035 et 2050...')),
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulation carbone – Année 2024',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              DashboardGauge(valeur: 7.2), // adapte ici si nécessaire
            ],
          ),
        ),
      ],
    );
  }
}
