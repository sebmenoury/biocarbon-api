import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/waterfall_chart.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';

class ObjectifsScreen extends StatefulWidget {
  const ObjectifsScreen({super.key});

  @override
  State<ObjectifsScreen> createState() => _ObjectifsScreenState();
}

class _ObjectifsScreenState extends State<ObjectifsScreen> {
  final String codeIndividu = "BASILE";
  final String valeurTemps = "2025";

  late Future<Map<String, Map<String, double>>> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = ApiService.getEmissionsByCategoryAndSousCategorie(
      codeIndividu,
      valeurTemps,
    );
  }

  double totalEmissions(Map<String, Map<String, double>> data) {
    return data.values.expand((e) => e.values).fold(0.0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: const Text(
        "Objectifs carbone",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      children: [
        FutureBuilder<Map<String, Map<String, double>>>(
          future: dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Erreur : ${snapshot.error}"),
              );
            }

            final data = snapshot.data!;
            final total = totalEmissions(data);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Projection de vos émissions annuelles",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 320,
                        child: WaterfallChart(
                          data: data.map((cat, sousCatMap) {
                            final short = AppText.shortLabel(cat);
                            return MapEntry(short, sousCatMap);
                          }),
                          palette: AppColors.categoryColors,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Total : ${total.toStringAsFixed(2)} tCO₂e/an",
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
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
