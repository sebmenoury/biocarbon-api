// vehicule_screen.dart
import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../data/services/api_service.dart';
import '../../data/classes/poste_vehicule.dart';
import '../../data/fonctions/emission_calculator_immobilier.dart';

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
        final poste = postes.firstWhere((p) => p.nomEquipement == nom, orElse: () => PosteVehicule(nomEquipement: nom));
        poste.facteurEmission = double.tryParse(eq['Valeur_Emission_Grise'].toString()) ?? 0;
        poste.dureeAmortissement = int.tryParse(eq['Duree_Amortissement'].toString()) ?? 1;

        final categorie = eq['Type_Equipement'] ?? 'Autres';
        result[categorie]?.add(poste);
      }
    }

    setState(() {
      vehiculesParCategorie = result;
      totalEmission = result.values
          .expand((e) => e)
          .fold(
            0.0,
            (sum, p) =>
                sum +
                calculerTotalEmission(p, {p.nomEquipement: p.facteurEmission}, {p.nomEquipement: p.dureeAmortissement}),
          );
      isLoading = false;
    });
  }

  Future<void> saveData() async {
    for (final categorie in vehiculesParCategorie.values) {
      for (final poste in categorie) {
        if (poste.quantite > 0) {
          final emission = calculerTotalEmission(
            poste,
            {poste.nomEquipement: poste.facteurEmission},
            {poste.nomEquipement: poste.dureeAmortissement},
          );
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
            "Annee_Achat": poste.anneeConstruction,
            "Duree_Amortissement": poste.dureeAmortissement,
          });
        }
      }
    }
    Navigator.pop(context);
  }

  Widget buildVehiculeRow(PosteBienImmobilier poste) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(poste.nomEquipement, style: const TextStyle(fontSize: 12))),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 14),
              onPressed: () => setState(() => poste.quantite = (poste.quantite - 1).clamp(0, 99)),
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
                  if (parsed != null) setState(() => poste.quantite = parsed);
                },
              ),
            ),
            IconButton(icon: const Icon(Icons.add, size: 14), onPressed: () => setState(() => poste.quantite += 1)),
            const SizedBox(width: 4),
            SizedBox(
              width: 50,
              child: TextFormField(
                initialValue: poste.anneeConstruction.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) setState(() => poste.anneeConstruction = parsed);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildCategorieCard(String titre, List<PosteBienImmobilier> vehicules) {
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
      title: const Text("Déclaration des véhicules", style: TextStyle(fontSize: 14)),
      children: [
        CustomCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Synthèse", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text("${totalEmission.toStringAsFixed(0)} kgCO₂", style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (vehiculesParCategorie['Voiture']!.isNotEmpty)
          buildCategorieCard("Voiture", vehiculesParCategorie['Voiture']!),
        if (vehiculesParCategorie['2-roues']!.isNotEmpty)
          buildCategorieCard("Scoot/Moto/Vélo", vehiculesParCategorie['2-roues']!),
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
