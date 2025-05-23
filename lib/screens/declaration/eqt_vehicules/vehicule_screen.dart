import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../../../data/classes/poste_vehicule.dart';
import 'emission_calculator_vehicules.dart';

class VehiculeScreen extends StatefulWidget {
  const VehiculeScreen({super.key});

  @override
  State<VehiculeScreen> createState() => _VehiculeScreenState();
}

class _VehiculeScreenState extends State<VehiculeScreen> {
  Map<String, List<PosteVehicule>> vehiculesParCategorie = {'Voitures': [], '2-roues': [], 'Autres': []};
  bool isLoading = true;
  double totalEmission = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final equipements = await ApiService.getRefEquipements();
    final postes = await ApiService.getPostesBysousCategorie("Véhicules", "BASILE", "2025");

    final Map<String, List<PosteVehicule>> result = {'Voitures': [], '2-roues': [], 'Autres': []};

    for (final eq in equipements) {
      if (eq['Type_Categorie'] == 'Déplacements' && eq['Sous_Categorie'] == 'Véhicules') {
        final nom = eq['Nom_Equipement'].toString();
        final facteur = double.tryParse(eq['Valeur_Emission_Grise'].toString()) ?? 0;
        final duree = int.tryParse(eq['Duree_Amortissement'].toString()) ?? 1;

        final nomLower = nom.toLowerCase();
        String categorie;
        if (nomLower.startsWith('voitures')) {
          categorie = 'Voitures';
        } else if (nomLower.startsWith('2-roues')) {
          categorie = '2-Roues';
        } else {
          categorie = 'Autres';
        }

        final postesPourCetEquipement = postes.where((p) => p.nomPoste == nom).toList();
        final annees = postesPourCetEquipement.map((p) => p.anneeAchat ?? DateTime.now().year).toList();
        if (annees.isEmpty) annees.add(DateTime.now().year);

        final poste = PosteVehicule(
          nomEquipement: nom,
          anneesConstruction: annees,
          quantite: postesPourCetEquipement.length,
        );
        poste.facteurEmission = facteur;
        poste.dureeAmortissement = duree;

        result[categorie]!.add(poste);
      }
    }

    setState(() {
      vehiculesParCategorie = result;
      recalculerTotal();
      isLoading = false;
    });
  }

  void recalculerTotal() {
    totalEmission = vehiculesParCategorie.values
        .expand((v) => v)
        .fold(0.0, (sum, p) => sum + calculerTotalEmissionVehicule(p));
  }

  Future<void> saveData() async {
    for (final categorie in vehiculesParCategorie.values) {
      for (final poste in categorie) {
        if (poste.quantite > 0) {
          final emission = calculerTotalEmissionVehicule(poste);
          await ApiService.savePoste({
            "Code_Individu": "BASILE",
            "Type_Temps": "Réel",
            "Valeur_Temps": "2025",
            "Date_enregistrement": DateTime.now().toIso8601String(),
            "Type_Poste": "Equipement",
            "Type_Categorie": "Déplacements",
            "Sous_Categorie": "Véhicules",
            "Nom_Poste": poste.nomEquipement,
            "Quantite": poste.quantite,
            "Unite": "unité",
            "Facteur_Emission": poste.facteurEmission,
            "Emission_Calculee": emission,
            "Mode_Calcul": "Amorti",
            "Annee_Achat": poste.anneesConstruction,
            "Duree_Amortissement": poste.dureeAmortissement,
          });
        }
      }
    }
    Navigator.pop(context);
  }

  Widget buildVehiculeLine(PosteVehicule poste) {
    String libelle = poste.nomEquipement.replaceFirst(RegExp(r'^(Voitures|2-roues|Autres)\s*-\s*'), '');
    final colorBloc = poste.quantite > 0 ? Colors.white : Colors.grey.shade100;

    List<int> anneesAAfficher;
    if (poste.anneesConstruction.isNotEmpty) {
      final max = poste.quantite > 0 ? poste.quantite : 1;
      anneesAAfficher = poste.anneesConstruction.take(max).toList();
    } else {
      anneesAAfficher = [DateTime.now().year];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(libelle, style: const TextStyle(fontSize: 12))),
          Container(
            width: 60,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: colorBloc,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 1, offset: const Offset(0, 1))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (poste.quantite > 0) {
                        poste.anneesConstruction.removeLast();
                        poste.quantite--;
                        recalculerTotal();
                      }
                    });
                  },
                  child: const Icon(Icons.remove, size: 14),
                ),
                Text('${poste.quantite}', style: const TextStyle(fontSize: 12)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      poste.anneesConstruction.add(DateTime.now().year);
                      poste.quantite++;
                      recalculerTotal();
                    });
                  },
                  child: const Icon(Icons.add, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Row(
            children: List.generate(anneesAAfficher.length, (index) {
              final annee = anneesAAfficher[index];
              final colorBloc = poste.quantite > 0 ? Colors.white : Colors.grey.shade100;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 90,
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: colorBloc,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 1, offset: const Offset(0, 1))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            poste.anneesConstruction[index] = poste.anneesConstruction[index] - 1;
                            recalculerTotal();
                          });
                        },
                        child: const Icon(Icons.remove, size: 14),
                      ),
                      SizedBox(
                        width: 40,
                        height: 24,
                        child: TextFormField(
                          key: ValueKey(annee),
                          initialValue: annee.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 6),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final an = int.tryParse(val);
                            if (an != null) {
                              setState(() {
                                poste.anneesConstruction[index] = an;
                                recalculerTotal();
                              });
                            }
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            poste.anneesConstruction[index] = poste.anneesConstruction[index] + 1;
                            recalculerTotal();
                          });
                        },
                        child: const Icon(Icons.add, size: 14),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildCategorieCard(String titre, List<PosteVehicule> vehicules) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...vehicules.map(buildVehiculeLine),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return BaseScreen(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 18,
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Text("Synthèse Véhicules déclarés", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
      children: [
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Empreinte annuelle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(
                "${totalEmission.toStringAsFixed(0)} kgCO₂",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...['Voitures', '2-roues', 'Autres'].map((groupe) {
          final items = vehiculesParCategorie[groupe]!;
          if (items.isNotEmpty) return buildCategorieCard(groupe, items);
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: saveData,
              icon: const Icon(Icons.save, size: 14),
              label: const Text("Enregistrer", style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
