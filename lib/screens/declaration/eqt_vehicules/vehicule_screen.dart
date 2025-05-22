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
        final nom = eq['Nom_Equipement'];
        final facteur = double.tryParse(eq['Valeur_Emission_Grise'].toString()) ?? 0;
        final duree = int.tryParse(eq['Duree_Amortissement'].toString()) ?? 1;

        final type = (eq['Type_Equipement'] ?? '').toString().toLowerCase();
        String categorie;
        if (type.contains('voiture')) {
          categorie = 'Voitures';
        } else if (type.contains('2-roues') || type.contains('moto') || type.contains('scoot')) {
          categorie = '2-roues';
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

        result[categorie] ??= [];
        result[categorie]!.add(poste);
      }
    }

    setState(() {
      vehiculesParCategorie = result;
      totalEmission = result.values.expand((e) => e).fold(0.0, (sum, p) => sum + calculerTotalEmissionVehicule(p));
      isLoading = false;
    });
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
            "Type_Categorie": "Logement",
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

  Widget buildVehiculeRow(PosteVehicule poste) {
    String libelle = poste.nomEquipement.replaceFirst(RegExp(r'^(Voitures|2-roues|Autres)\s*-\s*'), '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(libelle, style: const TextStyle(fontSize: 12))),
          Row(
            children: [
              SizedBox(
                width: 32,
                height: 28,
                child: Center(child: Text('${poste.quantite}', style: const TextStyle(fontSize: 12))),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        poste.anneesConstruction.add(DateTime.now().year);
                        poste.quantite = poste.anneesConstruction.length;
                      });
                    },
                    child: const Icon(Icons.arrow_drop_up, size: 20),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (poste.anneesConstruction.isNotEmpty) {
                          poste.anneesConstruction.removeLast();
                          poste.quantite = poste.anneesConstruction.length;
                        }
                      });
                    },
                    child: const Icon(Icons.arrow_drop_down, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          if (poste.quantite > 0)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: List.generate(poste.anneesConstruction.length, (index) {
                return SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: poste.anneesConstruction[index].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) {
                        setState(() {
                          poste.anneesConstruction[index] = parsed;
                        });
                      }
                    },
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
          ...vehicules.map(buildVehiculeRow).toList(),
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
          const Text("Vue d'ensemble Véhicules déclarés", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
      children: [
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Synthèse", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
