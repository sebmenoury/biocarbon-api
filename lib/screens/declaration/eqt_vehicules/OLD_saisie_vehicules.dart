import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';

class VehiculesScreen extends StatefulWidget {
  const VehiculesScreen({super.key});

  @override
  State<VehiculesScreen> createState() => _VehiculesScreenState();
}

class _VehiculesScreenState extends State<VehiculesScreen> {
  Map<String, double> facteursEmission = {};
  Map<String, int> dureesAmortissement = {};
  Map<String, int> quantites = {};
  Map<String, List<int>> anneesParVehicule = {};
  bool isLoading = true;
  double totalEmission = 0;

  @override
  void initState() {
    super.initState();
    loadVehicules();
  }

  Future<void> loadVehicules() async {
    try {
      final refEquipements = await ApiService.getRefEquipements();

      for (var e in refEquipements) {
        final nom = e['Nom_Equipement'];
        final facteur = double.tryParse(e['Valeur_Emission_Grise'].toString()) ?? 0;

        if (e['Type_Categorie'] == 'Véhicules') {
          facteursEmission[nom] = facteur;
          quantites[nom] = 0;
          anneesParVehicule[nom] = [];
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void increment(String nom) {
    setState(() {
      quantites[nom] = (quantites[nom] ?? 0) + 1;
      anneesParVehicule[nom]!.add(DateTime.now().year);
    });
    calculateEmission();
  }

  void decrement(String nom) {
    setState(() {
      if ((quantites[nom] ?? 0) > 0) {
        quantites[nom] = quantites[nom]! - 1;
        anneesParVehicule[nom]!.removeLast();
      }
    });
    calculateEmission();
  }

  void updateAnnee(String nom, int index, int annee) {
    setState(() {
      anneesParVehicule[nom]![index] = annee;
    });
  }

  void calculateEmission() {
    double total = 0;
    facteursEmission.forEach((nom, facteur) {
      final qte = quantites[nom] ?? 0;
      total += qte * facteur;
    });
    setState(() => totalEmission = total);
  }

  List<String> getVehiculesByGroupe(String groupe) {
    if (groupe == 'Voitures') {
      return facteursEmission.keys.where((k) => k.startsWith('Voitures')).toList();
    } else if (groupe == '2-roues') {
      return facteursEmission.keys.where((k) => k.contains('2-roues')).toList();
    } else {
      return facteursEmission.keys.where((k) => k.startsWith('Autres')).toList();
    }
  }

  Widget buildGroupe(String titre, List<String> vehicules) {
    return CustomCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            vehicules.map((nom) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(nom, style: const TextStyle(fontSize: 12))),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove), onPressed: () => decrement(nom), iconSize: 14),
                          Text('${quantites[nom] ?? 0}', style: const TextStyle(fontSize: 12)),
                          IconButton(icon: const Icon(Icons.add), onPressed: () => increment(nom), iconSize: 14),
                        ],
                      ),
                    ],
                  ),
                  for (int i = 0; i < (quantites[nom] ?? 0); i++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("Année :", style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            initialValue: anneesParVehicule[nom]![i].toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null) updateAnnee(nom, i, parsed);
                            },
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                ],
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: const Text("Véhicules", style: TextStyle(fontSize: 16)),
      children: [
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          /// Synthèse
          CustomCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Total estimé : ${totalEmission.toStringAsFixed(0)} kgCO₂/an",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          buildGroupe("Voiture", getVehiculesByGroupe('Voiture')),
          const SizedBox(height: 8),
          buildGroupe("2-roues", getVehiculesByGroupe('2-roues')),
          const SizedBox(height: 8),
          buildGroupe("Autres", getVehiculesByGroupe('Autres')),
        ],
      ],
    );
  }
}
