// lib/screens/mes_donnees_screen.dart
import 'package:flutter/material.dart';
import '../../ui/widgets/graph_card.dart';
import '../../ui/widgets/category_list_card.dart';
import '../../data/services/api_service.dart';

class MesDonneesScreen extends StatefulWidget {
  const MesDonneesScreen({super.key});

  @override
  State<MesDonneesScreen> createState() => _MesDonneesScreenState();
}

class _MesDonneesScreenState extends State<MesDonneesScreen> {
  late Future<Map<String, Map<String, double>>> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = fetchEmissionData();
  }

  double calculateTotal(Map<String, Map<String, double>> data) {
    return data.values.expand((s) => s.values).fold(0.0, (prev, e) => prev + e);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 390,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Mes Données", style: TextStyle(fontSize: 14)),
          ),
          body: FutureBuilder(
            future: dataFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data!;
                final typeCategories =
                    data.keys.toList()..sort((a, b) {
                      final sumA = data[a]!.values.fold(0.0, (p, v) => p + v);
                      final sumB = data[b]!.values.fold(0.0, (p, v) => p + v);
                      return sumB.compareTo(sumA);
                    });
                final total = calculateTotal(data);

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Total : ${total.toStringAsFixed(2)} tCO₂e/an",
                      style: const TextStyle(fontSize: 15),
                    ),
                    GraphCard(data: data),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: CategoryListCard(
                        data: data,
                        typeCategories: typeCategories,
                        total: total,
                      ),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(child: Text("Erreur : ${snapshot.error}"));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}
