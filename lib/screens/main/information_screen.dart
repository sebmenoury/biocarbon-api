import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Information',
      children: const [
        CustomCard(child: Text('Notions, documentation, pédagogie...')),
      ],
    );
  }
}
