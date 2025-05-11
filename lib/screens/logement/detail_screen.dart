import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';

class DetailScreen extends StatelessWidget {
  final String category;
  final Map<String, double> subData;

  const DetailScreen({
    super.key,
    required this.category,
    required this.subData,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Projection',
      children: const [
        CustomCard(child: Text('Trajectoire carbone projetée...')),
      ],
    );
  }
}
