import 'package:flutter/material.dart';
import '../usage_logement/poste_usage.dart';
import '../../../data/services/api_service.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../ui/layout/base_screen.dart';

class AlimentationScreen extends StatefulWidget {
  final String codeIndividu;
  final String valeurTemps;
  final VoidCallback onSave;

  const AlimentationScreen({super.key, required this.codeIndividu, required this.valeurTemps, required this.onSave});

  @override
  State<AlimentationScreen> createState() => _AlimentationScreenState();
}

class _AlimentationScreenState extends State<AlimentationScreen> {
  final Map<String, Map<String, dynamic>> regimes = {
    "Carnivore ++": {
      "emoji": "🍖",
      "desc": "Viande à chaque repas",
      "frequences": {'Boeuf': 7.0, 'Poisson': 3.0},
    },
    "Carnivore": {
      "emoji": "🥩",
      "desc": "Viande 1x/jour",
      "frequences": {'Boeuf': 5.0, 'Poisson': 2.0},
    },
    "Flexitarien": {
      "emoji": "🍗",
      "desc": "Viande 3–4x/semaine",
      "frequences": {'Boeuf': 2.0, 'Poisson': 2.0},
    },
    "Végétarien": {
      "emoji": "🥚",
      "desc": "Sans viande/poisson",
      "frequences": {'Oeuf': 3.0, 'Lait': 3.0},
    },
    "Végan": {"emoji": "🌿", "desc": "100% végétal", "frequences": {}},
  };

  String? selectedRegime;
  Map<String, double> frequencesAliments = {};

  final List<String> labels = ["jamais", "1/mois", "2/mois", "1/sem", "2/sem", "3/sem", "4/sem", "5/sem", "6/sem", "7/sem", "10/sem", "14/sem"];
  final List<double> values = [0, 0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 10, 14];

  void choisirRegime(String nom) async {
    final shouldApply = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Utiliser le profil $nom ?"),
            content: Text("Souhaitez-vous appliquer les fréquences suggérées pour ce régime ?"),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Non")), TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Oui"))],
          ),
    );

    if (shouldApply == true) {
      final map = regimes[nom]!['frequences'] as Map<String, dynamic>;
      frequencesAliments.clear();
      map.forEach((aliment, freq) {
        frequencesAliments[aliment] = (freq as num).toDouble();
      });
    }

    setState(() {
      selectedRegime = nom;
    });
  }

  Widget buildBoutonsFrequence(String aliment) {
    return Wrap(
      spacing: 4,
      children: List.generate(values.length, (i) {
        final actif = frequencesAliments[aliment] == values[i];
        return Tooltip(
          message: labels[i],
          child: GestureDetector(
            onTap: () {
              setState(() => frequencesAliments[aliment] = values[i]);
            },
            child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: actif ? Colors.green : Colors.grey.shade200)),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tousAliments = regimes.values.expand((Map<String, dynamic> r) => (r['frequences'] as Map<String, dynamic>).keys).toSet().toList();
    return Scaffold(
      appBar: AppBar(title: const Text("🥗 Alimentation")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quel est votre régime alimentaire ?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
              children:
                  regimes.entries.map((entry) {
                    final nom = entry.key;
                    final info = entry.value;
                    final selected = selectedRegime == nom;

                    return GestureDetector(
                      onTap: () => choisirRegime(nom),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: selected ? Colors.green : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: selected ? Colors.green.shade100 : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Text(info['emoji'], style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(info['desc'], style: const TextStyle(fontSize: 10))],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            const Text("Fréquence de consommation par aliment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...tousAliments.map((a) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(a, style: const TextStyle(fontSize: 13)), const SizedBox(height: 4), buildBoutonsFrequence(a), const SizedBox(height: 12)],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
