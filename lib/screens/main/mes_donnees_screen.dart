import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/dashboard_gauge.dart';
import '../../ui/widgets/category_list_card.dart';
import 'package:carbone_web/data/services/api_service.dart';

class MesDonneesScreen extends StatefulWidget {
  const MesDonneesScreen({super.key});

  @override
  State<MesDonneesScreen> createState() => _MesDonneesScreenState();
}

class _MesDonneesScreenState extends State<MesDonneesScreen> {
  String filtre = "Tous"; // "Tous", "Equipements", "Usages"
  final String codeIndividu = "BASILE";
  final String valeurTemps = "2025";

  late Future<Map<String, Map<String, double>>> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = ApiService.getEmissionsByTypeAndYearAndUser(
      filtre,
      codeIndividu,
      valeurTemps,
    );
  }

  void majFiltre(String nouveau) {
    setState(() {
      filtre = nouveau;
      dataFuture = ApiService.getEmissionsByTypeAndYearAndUser(
        filtre,
        codeIndividu,
        valeurTemps,
      );
    });
  }

  double totalEmissions(Map<String, Map<String, double>> data) {
    return data.values.expand((s) => s.values).fold(0.0, (acc, e) => acc + e);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: "Mes Données",
      children: [
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                ["Tous", "Equipements", "Usages"].map((option) {
                  final isSelected = option == filtre;
                  return GestureDetector(
                    onTap: () => majFiltre(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? Colors.indigo : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        FutureBuilder<Map<String, Map<String, double>>>(
          future: dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erreur : ${snapshot.error}"));
            }
            final data = snapshot.data!;
            final typeCategories =
                data.keys.toList()..sort((a, b) {
                  final sumA = data[a]!.values.fold(0.0, (p, v) => p + v);
                  final sumB = data[b]!.values.fold(0.0, (p, v) => p + v);
                  return sumB.compareTo(sumA);
                });
            final total = totalEmissions(data);

            return Column(
              children: [
                CustomCard(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      DashboardGauge(valeur: total),
                      const SizedBox(height: 8),
                      Text(
                        "$filtre — $total tCO₂e/an",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomCard(
                  child: CategoryListCard(
                    data: data,
                    typeCategories: typeCategories,
                    total: total,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
