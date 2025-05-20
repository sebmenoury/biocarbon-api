import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: const Text("Informations", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      children: const [CustomCard(child: Text('Notions, documentation, pédagogie...'))],
    );
  }
}
