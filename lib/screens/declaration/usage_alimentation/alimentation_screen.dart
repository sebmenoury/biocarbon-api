import 'package:flutter/material.dart';
import '../usage_logement/poste_usage.dart';
import '../../../data/services/api_service.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../ui/layout/base_screen.dart';
import "poste_alimentaire.dart";

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

  double calculerTotalEmission() {
    return aliments.fold(0.0, (total, aliment) {
      if (aliment.frequence != null) {
        return total + (aliment.portion * aliment.frequence! * 52 * aliment.facteur!);
      }
      return total;
    });
  }

  final List<String> labels = ["jamais", "1/mois", "2/mois", "1/sem", "2/sem", "3/sem", "4/sem", "5/sem", "6/sem", "7/sem", "10/sem", "14/sem"];
  final List<double> values = [0, 0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 10, 14];

  String? selectedRegime;
  Map<String, double> frequencesAliments = {};

  Future<List<PosteAlimentaire>> chargerAliments() async {
    final ref = await ApiService.getRefAlimentation();

    return ref.map<PosteAlimentaire>((r) {
      final nom = r['Nom_Usage'];

      return PosteAlimentaire(nom: nom, portion: (r['Portion'] as num).toDouble(), unite: r['Unite'], sousCategorie: r['Sous_Categorie'], facteur: (r['Valeur_Emission_Unitaire'] as num).toDouble());
    }).toList();
  }

  List<PosteAlimentaire> aliments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chargerAliments().then((value) {
      setState(() {
        aliments = value;
        isLoading = false;
      });
    });
  }

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

      for (final aliment in aliments) {
        if (map.containsKey(aliment.nom)) {
          aliment.frequence = (map[aliment.nom] as num).toDouble();
        } else {
          aliment.frequence = null; // ou null si tu préfères
        }
      }
    }

    setState(() {
      selectedRegime = nom;
    });
  }

  Widget buildGroupedCards() {
    final grouped = <String, List<PosteAlimentaire>>{};
    for (var a in aliments) {
      grouped.putIfAbsent(a.sousCategorie ?? 'Autres', () => []).add(a);
    }

    return Column(
      children:
          grouped.entries.map((entry) {
            final group = entry.key;
            final alimentsGroupe = entry.value;

            return CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...alimentsGroupe.map(
                    (a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [SizedBox(width: 100, child: Text(a.nom, style: const TextStyle(fontSize: 11))), const SizedBox(width: 8), Expanded(child: buildBoutonsFrequence(a))],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget buildBoutonsFrequence(PosteAlimentaire aliment) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(values.length, (i) {
        final actif = aliment.frequence == values[i];
        return Tooltip(
          message: labels[i],
          child: GestureDetector(
            onTap: () {
              setState(() {
                aliment.frequence = values[i];
              });
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400), color: actif ? Colors.green.shade500 : Colors.grey.shade200),
              child: actif ? Center(child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white))) : null,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tousAliments = aliments.map((a) => a.nom).toList()..sort();

    if (isLoading) {
      return const BaseScreen(title: Text("Chargement…"), child: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: BaseScreen(
          title: Stack(
            alignment: Alignment.center,
            children: [
              const Center(child: Text("Caractéristiques de votre alimentation", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100, top: 8), // marge pour FAB
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "⚙️ Vous pouvez soit choisir un régime alimentaire type pour initialiser les valeurs de fréquence, soit directement sélectionner les fréquences de consommation de ces aliments.",
                    style: TextStyle(fontSize: 11),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 8),
                CustomCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.restaurant, size: 16, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          const Text("Empreinte totale", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text("${calculerTotalEmission().toStringAsFixed(0)} kgCO₂/an", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.only(left: 12), child: Text("Quel est votre régime alimentaire ?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(height: 4),
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
                                const SizedBox(width: 4),
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
                Padding(padding: const EdgeInsets.only(left: 12), child: Text("Indiquez la fréquence de consommation par aliment", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                buildGroupedCards(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
