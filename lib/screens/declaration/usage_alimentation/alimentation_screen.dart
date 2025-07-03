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
      "frequences": {"Boeuf": 10, "Poulet": 4},
    },
    "Carnivore": {
      "emoji": "🥩",
      "desc": "Viande 1x/jour",
      "frequences": {"Boeuf": 5, "Poulet": 3},
    },
    "Flexitarien": {
      "emoji": "🍗",
      "desc": "Viande 3–4×/semaine",
      "frequences": {"Boeuf": 2, "Poisson": 2},
    },
    "Végétarien": {
      "emoji": "🥚",
      "desc": "Sans viande/poisson",
      "frequences": {"Oeuf": 4, "Lait": 4},
    },
    "Végan": {
      "emoji": "🌿",
      "desc": "100% végétal",
      "frequences": {"Légumes": 14},
    },
  };

  final List<String> labels = ["jamais", "1/mois", "2/mois", "1/sem", "2/sem", "3/sem", "4/sem", "5/sem", "6/sem", "7/sem", "10/sem", "14/sem"];
  final List<double> values = [0, 0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 10, 14];

  String? selectedRegime;
  Map<String, double> frequencesAliments = {};

  Future<void> choisirRegime(String nom) async {
    final shouldApply = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Utiliser le profil $nom ?"),
            content: const Text("Souhaitez-vous appliquer les fréquences suggérées pour ce régime ?"),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui"))],
          ),
    );

    if (shouldApply == true) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(regimes[nom]!['frequences']);
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
      spacing: 6,
      runSpacing: 6,
      children: List.generate(values.length, (i) {
        final actif = frequencesAliments[aliment] == values[i];
        return Tooltip(
          message: labels[i],
          child: GestureDetector(
            onTap: () {
              setState(() => frequencesAliments[aliment] = values[i]);
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400), color: actif ? Colors.green.shade500 : Colors.grey.shade200),
              child: actif ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white))) : null,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tousAliments = regimes.values.expand((r) => (r['frequences'] as Map<String, dynamic>).keys).toSet().toList()..sort();

    return BaseScreen(
      title: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          const Text("Caractéristiques de votre alimentation", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
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
                    child: CustomCard(
                      padding: const EdgeInsets.all(8),
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
          const SizedBox(height: 16),
          const Text("Fréquence de consommation par aliment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...tousAliments.map((a) {
            return CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a, style: const TextStyle(fontSize: 13)), const SizedBox(height: 6), buildBoutonsFrequence(a)]),
            );
          }).toList(),
        ],
      ),
    );
  }
}
