import 'package:carbone_web/screens/detail/subcategory_screen.dart';
import 'package:flutter/material.dart';
import 'package:carbone_web/core/constants/app_icons.dart';

class CategoryListCard extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final List<String> typeCategories;
  final double total;
  final String codeIndividu;
  final String valeurTemps;

  const CategoryListCard({
    super.key,
    required this.data,
    required this.typeCategories,
    required this.total,
    required this.codeIndividu,
    required this.valeurTemps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(typeCategories.length, (index) {
          final category = typeCategories[index];
          final emissions = data[category]!.values.reduce((a, b) => a + b);
          final percentage = ((emissions / total) * 100).toStringAsFixed(0);

          return Column(
            children: [
              ListTile(
                isThreeLine: false,
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                minVerticalPadding: 6,
                leading: Icon(
                  categoryIcons[category] ?? Icons.label_outline,
                  size: 16,
                  color: categoryColors[category] ?? Colors.grey[700],
                ),
                title: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "$percentage%",
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${emissions.toStringAsFixed(2)} tCO₂e",
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 14),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SubCategorieScreen(
                            typeCategorie: category,
                            codeIndividu: codeIndividu,
                            valeurTemps: valeurTemps,
                          ),
                    ),
                  );
                },
              ),
              if (index < typeCategories.length - 1) const Divider(height: 1),
            ],
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }
}
