import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/dashboard_gauge.dart';
import '../../ui/widgets/category_list_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MesDonneesScreen extends StatefulWidget {
  const MesDonneesScreen({super.key});

  @override
  State<MesDonneesScreen> createState() => _MesDonneesScreenState();
}

enum DataViewType { tous, equipements, usages }

class _MesDonneesScreenState extends State<MesDonneesScreen> {
  DataViewType _selectedView = DataViewType.tous;
  double totalEmission = 0;
  Map<String, Map<String, double>> emissionsByCategory = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final equipementsUri = Uri.parse(
      'https://biocarbon-api.onrender.com/api/uc/equipements',
    );
    final usagesUri = Uri.parse(
      'https://biocarbon-api.onrender.com/api/uc/usages',
    );

    final equipRes = await http.get(equipementsUri);
    final usageRes = await http.get(usagesUri);

    if (equipRes.statusCode == 200 && usageRes.statusCode == 200) {
      final List<dynamic> allEquipements = jsonDecode(equipRes.body);
      final List<dynamic> allUsages = jsonDecode(usageRes.body);

      List<dynamic> data;
      switch (_selectedView) {
        case DataViewType.equipements:
          data = allEquipements;
          break;
        case DataViewType.usages:
          data = allUsages;
          break;
        default:
          data = [...allEquipements, ...allUsages];
      }

      totalEmission = 0;
      emissionsByCategory = {};

      for (var item in data) {
        double emission =
            double.tryParse(item['Emission_Estimee'].toString()) ?? 0;
        String cat = item['Type_Categorie'] ?? 'Inconnu';
        String sousCat = item['Sous_Categorie'] ?? 'Autre';

        totalEmission += emission;
        emissionsByCategory.putIfAbsent(cat, () => {});
        emissionsByCategory[cat]!.update(
          sousCat,
          (v) => v + emission,
          ifAbsent: () => emission,
        );
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: "Mes données",
      children: [
        _buildTypeSelector(),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          CustomCard(child: DashboardGauge(valeur: totalEmission)),
          const SizedBox(height: 8),
          CustomCard(child: CategoryListCard(data: emissionsByCategory)),
        ],
      ],
    );
  }

  Widget _buildTypeSelector() {
    return CustomCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            DataViewType.values.map((type) {
              final label =
                  {
                    DataViewType.tous: "Tous",
                    DataViewType.equipements: "Équipements",
                    DataViewType.usages: "Usages",
                  }[type]!;

              final isSelected = _selectedView == type;

              return GestureDetector(
                onTap: () async {
                  setState(() => _selectedView = type);
                  await _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue.shade100 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue[800] : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
