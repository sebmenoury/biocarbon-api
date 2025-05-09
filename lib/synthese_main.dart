// lib/main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'emission_progress_bar.dart';
import 'construction_screen.dart';
import 'WaterfallChartScreen.dart';
import 'app.dart';

void main() {
  runApp(const App());
}

class GreenWayApp extends StatelessWidget {
  const GreenWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Empreinte Carbone',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const SyntheseScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SyntheseScreen extends StatefulWidget {
  const SyntheseScreen({super.key});

  @override
  State<SyntheseScreen> createState() => _SyntheseScreenState();
}

final Map<String, IconData> categoryIcons = {
  "Logement": Icons.home_rounded,
  "Déplacement": Icons.directions_car_filled_rounded,
  "Services": Icons.miscellaneous_services_rounded,
  "Alimentation": Icons.restaurant_rounded,
  "Biens": Icons.shopping_bag_rounded,
};

const Map<String, double> cible2035 = {
  "Biens": 800,
  "Services": 1000,
  "Logement": 1000,
  "Déplacement": 1500,
  "Alimentation": 1400,
};

const Map<String, double> cible2050 = {
  "Biens": 200,
  "Services": 300,
  "Logement": 400,
  "Déplacement": 500,
  "Alimentation": 600,
};

class _SyntheseScreenState extends State<SyntheseScreen> {
  late Future<Map<String, Map<String, double>>> dataFuture;

  int _selectedIndex = 0; // à placer dans ton State

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      // 3ᵉ item : "Objectifs"
      final emissionData = await dataFuture;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WaterfallChartScreen(
                data: emissionData, // mets ici ta variable réelle
                palette: palette, // ex : {'Logement': Colors.blue, ...}
              ),
        ),
      );
    }

    // Tu peux aussi gérer les autres index si besoin (Analyse, Ajout, etc.)
  }

  final palette = {
    // Alimentation
    "Viande": Color(0xFF80350E),
    "Poisson": Color(0xFFC04F15),
    "Laits et œufs": Color(0xFFF2AA84),
    "Fruits et légumes": Color(0xFFF6C6AD),
    "Céréales et autres": Color(0xFFE97132),
    "Boissons": Color(0xFFFBE3D6),
    "Déchets / Eau": Color(0xFFC37545),

    // Biens
    "Digital": Color(0xFF275317),
    "Eqt. Ménager": Color(0xFF3B7D23),
    "Bricolage": Color(0xFF4EA72E),
    "Vêtements": Color(0xFF8ED973),

    // Déplacements
    "Véhicules": Color(0xFF084F6A),
    "Avion": Color(0xFF0B76A0),
    "Voiture": Color(0xFF0F9ED5),
    "Train": Color(0xFF61CBF4),
    "Car/Bus/Métro/tram": Color(0xFF96DCF8),
    "2-roues": Color(0xFFCAEEFB),
    "Autres": Color(0xFFDCEAF7),

    // Logement
    "Construction": Color(0xFF50164A),
    "Gaz et fioul": Color(0xFF78206E),
    "Électricité": Color(0xFFA02B93),
    "Eqt. Confort": Color(0xFFD86ECC),
    "Renov. Confort": Color(0xFFE59EDD),

    // Services
    "Assurance, Banque": Color(0xFF8F7801),
    "Loisirs": Color(0xFFD7B402),
    "Enseignement": Color(0xFFF5B75B),
    "Sport et Culture": Color(0xFFFEDDA24),
    "Autres publics": Color(0xFFFEE97C),
    "Admin. et défense": Color(0xFFFEF0A7),
    "Santé": Color(0xFFFFF8D3),
    "Infrastructure": Color(0xFFFFFAE1),
  };

  @override
  void initState() {
    super.initState();
    dataFuture = fetchData();
  }

  Future<Map<String, Map<String, double>>> fetchData() async {
    final url = Uri.parse(
      "http://127.0.0.1:5000/synthese?individu=BASILE&annee=2025",
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final Map<String, Map<String, double>> grouped = {};
      for (var item in data) {
        final type = item["Type_Categorie"];
        final sous = item["Sous_Categorie"];
        final value = (item["Emissions_CO2_kg"] as num).toDouble() / 1000;
        grouped[type] ??= {};
        grouped[type]![sous] = value;
      }
      return grouped;
    } else {
      throw Exception("Erreur API");
    }
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
            title: const Text(
              "Empreinte Carbone",
              style: TextStyle(fontSize: 14), // Ajuste la taille ici
            ),
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

                    // Graphique : 50% de la hauteur de l'écran
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.44,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: BarChart(
                          BarChartData(
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.black.withOpacity(0.8),
                                getTooltipItem: (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) {
                                  final cat = typeCategories[group.x.toInt()];
                                  final sousCats = data[cat]!;
                                  final tooltipText = sousCats.entries
                                      .map(
                                        (e) =>
                                            '${e.key} : ${e.value.toStringAsFixed(2)} t',
                                      )
                                      .join('\n');
                                  return BarTooltipItem(
                                    tooltipText,
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  );
                                },
                              ),
                            ),
                            alignment: BarChartAlignment.spaceAround,
                            maxY:
                                data.values
                                    .map(
                                      (m) => m.values.reduce((a, b) => a + b),
                                    )
                                    .reduce((a, b) => a > b ? a : b) *
                                1.3,
                            barGroups: List.generate(typeCategories.length, (
                              i,
                            ) {
                              final cat = typeCategories[i];
                              final sousCats = data[cat]!;
                              double startY = 0;
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: sousCats.values.reduce(
                                      (a, b) => a + b,
                                    ),
                                    rodStackItems:
                                        sousCats.entries.map((entry) {
                                          final color =
                                              palette[entry.key] ?? Colors.grey;
                                          final item = BarChartRodStackItem(
                                            startY,
                                            startY + entry.value,
                                            color,
                                          );
                                          startY += entry.value;
                                          return item;
                                        }).toList(),
                                    width: 26,
                                  ),
                                ],
                              );
                            }),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                axisNameWidget: RotatedBox(
                                  quarterTurns: 4,
                                  child: SizedBox(
                                    height: 140,
                                    width: 200,
                                    child: Center(
                                      child: Text(
                                        'tCO₂e/an',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    if (value == meta.max)
                                      return Container(); // Cache le label max
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(fontSize: 8),
                                      textAlign: TextAlign.right,
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 48,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 ||
                                        index >= typeCategories.length)
                                      return const SizedBox.shrink();
                                    final category = typeCategories[index];
                                    final emissions = data[category]!.values
                                        .reduce((a, b) => a + b);
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            category,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '${emissions.toStringAsFixed(2)} t',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ),

                    // Ligne de séparation
                    const Divider(height: 1, thickness: 1),

                    // Liste compacte
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: typeCategories.length,
                        itemBuilder: (context, index) {
                          final category = typeCategories[index];
                          final emissions = data[category]!.values.reduce(
                            (a, b) => a + b,
                          );
                          final percentage = ((emissions / total) * 100)
                              .toStringAsFixed(0);

                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: 0,
                                  vertical: -4,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                minVerticalPadding: 0,

                                //leading: const Icon(Icons.home, size: 12), // 🏠 À adapter selon catégorie
                                leading: Icon(
                                  categoryIcons[category] ??
                                      Icons.label_outline, // fallback icon
                                  size: 14,
                                  color: Colors.grey[700],
                                ),

                                title: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '$percentage%',
                                  style: const TextStyle(fontSize: 8),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${emissions.toStringAsFixed(2)} tCO₂e',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, size: 12),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => DetailScreen(
                                            category: category,
                                            subData: data[category]!,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        },
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

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped, // ← ajoute ceci
            selectedItemColor: Colors.green[700],
            unselectedItemColor: Colors.grey,
            iconSize: 18,
            selectedFontSize: 9,
            unselectedFontSize: 9,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: "Analyse",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: "Ajouter une mesure",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flag_outlined),
                label: "Objectifs",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tips_and_updates_outlined),
                label: "Idées",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline),
                label: "Information",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final total = subData.values.reduce((a, b) => a + b);

    // Tri décroissant sur les valeurs
    final sortedEntries =
        subData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Center(
      child: SizedBox(
        width: 390, // Simule un écran iPhone
        child: Scaffold(
          appBar: AppBar(title: Text(category)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EmissionProgressBar(
                valeurActuelle:
                    total * 1000, // converti en kg si ton total est en tCO₂e
                cible2035: cible2035[category]!,
                cible2050: cible2050[category]!,
              ),
              const SizedBox(height: 16),
              const Divider(),

              // Liste des sous-catégories
              ...sortedEntries.map((entry) {
                final subCat = entry.key;
                final emissions = entry.value;
                final percentage = ((emissions / total) * 100).toStringAsFixed(
                  0,
                );

                return Column(
                  children: [
                    ListTile(
                      visualDensity: const VisualDensity(
                        horizontal: 0,
                        vertical: -4,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      minVerticalPadding: 0,
                      dense: true,
                      title: Text(
                        subCat,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '$percentage%',
                        style: const TextStyle(fontSize: 8),
                      ),
                      trailing: Text(
                        '${emissions.toStringAsFixed(2)} tCO₂e',
                        style: const TextStyle(fontSize: 10),
                      ),
                      onTap: () {
                        if (subCat == "Construction") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConstructionScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0, // ou selon la navigation actuelle
            selectedItemColor: Colors.green[700],
            unselectedItemColor: Colors.grey,
            iconSize: 18, // plus petit
            selectedFontSize: 9,
            unselectedFontSize: 9,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: "Analyse",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: "Ajouter une mesure",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flag_outlined),
                label: "Objectifs",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tips_and_updates_outlined),
                label: "Idées",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline),
                label: "Information",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
