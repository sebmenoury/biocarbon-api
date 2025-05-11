import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';

class ConstructionScreen extends StatefulWidget {
  const ConstructionScreen({super.key});

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  final TextEditingController surfaceLogementController =
      TextEditingController();
  final TextEditingController surfaceGarageController = TextEditingController();
  final TextEditingController surfacePiscineController =
      TextEditingController();
  final TextEditingController surfaceJardinController = TextEditingController();

  String typeLogement = "Maison";
  int anneeConstruction = 2000;
  int nbLogements = 1;

  double emissionTotale = 0;

  void calculerEmission() {
    double logement = double.tryParse(surfaceLogementController.text) ?? 0;
    double garage = double.tryParse(surfaceGarageController.text) ?? 0;
    double piscine = double.tryParse(surfacePiscineController.text) ?? 0;
    double jardin = double.tryParse(surfaceJardinController.text) ?? 0;

    // À remplacer par des appels API dynamiques
    const facteurMaison = 7.5; // kgCO2/m²
    const facteurGarage = 5.0;
    const facteurPiscine = 12.0;
    const facteurJardin = 3.0;

    final logementEmission = logement * facteurMaison;
    final garageEmission = garage * facteurGarage;
    final piscineEmission = piscine * facteurPiscine;
    final jardinEmission = jardin * facteurJardin;

    setState(() {
      emissionTotale =
          logementEmission + garageEmission + piscineEmission + jardinEmission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: "Construction du logement",
      children: [
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Type de logement"),
              DropdownButton<String>(
                value: typeLogement,
                onChanged: (value) => setState(() => typeLogement = value!),
                items: const [
                  DropdownMenuItem(value: "Maison", child: Text("Maison")),
                  DropdownMenuItem(
                    value: "Appartement",
                    child: Text("Appartement"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Année de construction"),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => setState(() => anneeConstruction--),
                  ),
                  Text(anneeConstruction.toString()),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => anneeConstruction++),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Surface logement (m²)"),
              TextField(
                controller: surfaceLogementController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text("Surface garage (m²)"),
              TextField(
                controller: surfaceGarageController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text("Surface piscine (m²)"),
              TextField(
                controller: surfacePiscineController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text("Surface jardin (m²)"),
              TextField(
                controller: surfaceJardinController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: calculerEmission,
                child: const Text("Calculer émission"),
              ),
              const SizedBox(height: 10),
              Text(
                "Émission estimée : ${emissionTotale.toStringAsFixed(1)} kg CO₂e",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
