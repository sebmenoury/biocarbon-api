import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/graphs/graph_card.dart';
import '../../ui/widgets/category_list_card.dart';
import '../../data/services/api_service.dart';

class ProjectionScreen extends StatefulWidget {
  const ProjectionScreen({super.key});

  @override
  State<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen> {
  late Future<Map<String, Map<String, double>>> dataFuture;
  String filtre = "Tous"; // "Tous", "Equipements", "Usages"
  final String codeIndividu = "BASILE";
  final String valeurTemps = '2025';

  @override
  void initState() {
    super.initState();
    dataFuture = ApiService.getEmissionsAggregated(codeIndividu: codeIndividu, valeurTemps: valeurTemps, groupByFields: ['Type_Categorie']);
  }

  double calculateTotal(Map<String, Map<String, double>> data) {
    return data.values.expand((s) => s.values).fold(0.0, (prev, e) => prev + e);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: const Text("Projection", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      children: [
        const CustomCard(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), child: Text('Trajectoire carbone projetée...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        FutureBuilder<Map<String, Map<String, double>>>(
          future: dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: \${snapshot.error}'));
            } else if (snapshot.hasData) {
              final data = snapshot.data!;
              final typeCategories =
                  data.keys.toList()..sort((a, b) {
                    final sumA = data[a]!.values.fold(0.0, (p, v) => p + v);
                    final sumB = data[b]!.values.fold(0.0, (p, v) => p + v);
                    return sumB.compareTo(sumA);
                  });
              final total = calculateTotal(data);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Niveau Emission : ${total.toStringAsFixed(2)} tCO₂e/an", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        GraphCard(data: data, compactLeftLegend: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomCard(
                    child: CategoryListCard(
                      data: data,
                      typeCategories: typeCategories,
                      total: total,
                      codeIndividu: "BASILE", // ou ta variable
                      valeurTemps: '2025', // ou ta variable
                    ),
                  ),
                ],
              );
            } else {
              return const Center(child: Text('No data available'));
            }
          },
        ),
      ],
    );
  }
}
