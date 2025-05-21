import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/graphs/dashboard_gauge.dart';
import '../../ui/widgets/category_list_card.dart';
import '../../data/services/api_service.dart';

class AnalyseScreen extends StatefulWidget {
  const AnalyseScreen({super.key});

  @override
  State<AnalyseScreen> createState() => _AnalyseScreenState();
}

class _AnalyseScreenState extends State<AnalyseScreen> {
  String filtre = "Tous"; // "Tous", "Equipements", "Usages"
  final String codeIndividu = "BASILE";
  final String valeurTemps = "2025";

  late Future<Map<String, Map<String, double>>> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = fetchData();
  }

  void majFiltre(String nouveau) {
    setState(() {
      filtre = nouveau;
      dataFuture = fetchData();
    });
  }

  Future<Map<String, Map<String, double>>> fetchData() {
    if (filtre == "Tous") {
      return ApiService.getEmissionsByTypeAndYearAndUser(filtre, codeIndividu, valeurTemps);
    } else {
      return ApiService.getEmissionsFilteredByTypePosteGroupedByCategorie(
        filtre.substring(0, filtre.length - 1), // "Usages" → "Usage"
        codeIndividu,
        valeurTemps,
      );
    }
  }

  double totalEmissions(Map<String, Map<String, double>> data) {
    return data.values.expand((s) => s.values).fold(0.0, (acc, e) => acc + e);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: const Text("Analyse des données", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      children: [
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                ["Tous", "Equipements", "Usages"].map((option) {
                  final isSelected = option == filtre;
                  return GestureDetector(
                    onTap: () => majFiltre(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.indigo : Colors.white),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              return Center(child: Text("Erreur : \${snapshot.error}"));
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
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Simulation carbone – Année 2024',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 30),
                        DashboardGauge(valeur: total * 1000),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Niveau d'émission carbone",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                "Données annuelles en kg CO₂e / personne",
                                style: TextStyle(fontSize: 8, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CustomCard(
                  child: CategoryListCard(
                    data: data,
                    typeCategories: typeCategories,
                    total: total,
                    codeIndividu: codeIndividu,
                    valeurTemps: valeurTemps,
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
