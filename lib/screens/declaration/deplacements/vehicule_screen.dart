// vehicule_screen.dart
import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../../../data/classes/poste_vehicule.dart';
import '../eqt_vehicules/emission_calculator_vehicules.dart';

class VehiculeScreen extends StatefulWidget {
  const VehiculeScreen({super.key});

  @override
  State<VehiculeScreen> createState() => _VehiculeScreenState();
}

class _VehiculeScreenState extends State<VehiculeScreen> {
  List<Map<String, dynamic>> refEquipements = [];
  Map<String, List<PosteVehicule>> vehiculesParCategorie = {};
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

    final Map<String, List<PosteVehicule>> result = {'Voiture': [], '2-roues': [], 'Autres': []};

    for (final eq in equipements) {
      if (eq['Type_Categorie'] == 'Déplacements' && eq['Sous_Categorie'] == 'Véhicules') {
        final nom = eq['Nom_Equipement'];
        final facteur = double.tryParse(eq['Valeur_Emission_Grise'].toString()) ?? 0;
        final duree = int.tryParse(eq['Duree_Amortissement'].toString()) ?? 1;

        // Cherche tous les postes UC correspondant à ce véhicule
        final postesPourCetEquipement = postes.where((p) => p.nomPoste == nom).toList();

        // Récupère les années ou initialise vide
        final annees = postesPourCetEquipement.map((p) => p.anneeAchat ?? DateTime.now().year).toList();

        // S'il n’y a rien de déclaré, on met une seule ligne vide
        if (annees.isEmpty) annees.add(DateTime.now().year);

        final poste = PosteVehicule(nomEquipement: nom, anneesConstruction: annees);

        poste.facteurEmission = facteur;
        poste.dureeAmortissement = duree;

        final categorie = eq['Type_Equipement'] ?? 'Autres';
        result[categorie]?.add(poste);
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
          await ApiService.saveOrUpdatePoste({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne du nom + boutons +/- + champ quantité
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(poste.nomEquipement, style: const TextStyle(fontSize: 12))),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 14),
                  onPressed: () {
                    setState(() {
                      if (poste.anneesConstruction.isNotEmpty) {
                        poste.anneesConstruction.removeLast();
                      }
                    });
                  },
                ),
                SizedBox(
                  width: 32,
                  child: TextFormField(
                    initialValue: poste.quantite.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 0) {
                        setState(() {
                          // ajuster la longueur de la liste
                          final current = poste.anneesConstruction;
                          if (parsed > current.length) {
                            current.addAll(List.generate(parsed - current.length, (_) => DateTime.now().year));
                          } else if (parsed < current.length) {
                            current.removeRange(parsed, current.length);
                          }
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 14),
                  onPressed: () {
                    setState(() {
                      poste.anneesConstruction.add(DateTime.now().year);
                    });
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Champs d'année pour chaque véhicule
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
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 6), border: OutlineInputBorder()),
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
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildCategorieCard(String titre, List<PosteVehicule> vehicules) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 8), ...vehicules.map((v) => buildVehiculeRow(v)).toList()],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return BaseScreen(
      title: const Text("Déclaration des véhicules", style: TextStyle(fontSize: 14)),
      children: [
        CustomCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text("Synthèse", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text("${totalEmission.toStringAsFixed(0)} kgCO₂", style: const TextStyle(fontSize: 12))],
          ),
        ),
        const SizedBox(height: 6),
        if (vehiculesParCategorie['Voiture']!.isNotEmpty) buildCategorieCard("Voiture", vehiculesParCategorie['Voiture']!),
        if (vehiculesParCategorie['2-roues']!.isNotEmpty) buildCategorieCard("Scoot/Moto/Vélo", vehiculesParCategorie['2-roues']!),
        if (vehiculesParCategorie['Autres']!.isNotEmpty) buildCategorieCard("Autres", vehiculesParCategorie['Autres']!),
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
