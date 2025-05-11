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
      title: category,
      child: Column(
        children: [
          CustomCard(
            child: Text('📈 Trajectoire carbone projetée pour $category'),
          ),
          const SizedBox(height: 12),
          ...subData.entries.map(
            (e) => CustomCard(
              child: ListTile(
                title: Text(e.key),
                trailing: Text('${e.value.toStringAsFixed(2)} tCO₂e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
