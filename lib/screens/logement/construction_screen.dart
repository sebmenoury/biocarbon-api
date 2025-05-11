import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../data/services/api_service.dart';

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

  Map<String, TextEditingController> confortControllers = {};

  String typeLogement = "Maison";
  int anneeConstruction = 2000;

  double emissionTotale = 0;
  Map<String, double> facteursEmission = {};
  Map<String, int> dureesAmortissement = {};
  bool isLoading = true;

  final List<Map<String, dynamic>> equipementsConfort = [
    {"nom": "Poële à granule", "unite": "unité"},
    {"nom": "Radiateur électrique", "unite": "unité"},
    {"nom": "Pompe à chaleur", "unite": "unité"},
  ];

  @override
  void initState() {
    super.initState();
    for (var eq in equipementsConfort) {
      confortControllers[eq["nom"]] = TextEditingController();
    }
    loadFacteursEtDurees();
  }

  Future<void> loadFacteursEtDurees() async {
    try {
      final facteurs = await ApiService.getEmissionFactors();
      final durees = await ApiService.getDureeAmortissement();
      setState(() {
        facteursEmission = facteurs;
        dureesAmortissement = durees;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Erreur chargement facteurs ou durées : $e");
    }
  }

  void calculerEmission() {
    double logement = double.tryParse(surfaceLogementController.text) ?? 0;
    double garage = double.tryParse(surfaceGarageController.text) ?? 0;
    double piscine = double.tryParse(surfacePiscineController.text) ?? 0;
    double jardin = double.tryParse(surfaceJardinController.text) ?? 0;

    const noms = {
      "logement": "Maison Classique",
      "garage": "Garage béton",
      "piscine": "Piscine extérieure",
      "jardin": "Abri de jardin",
    };

    double total = 0;
    final elements = {
      noms["logement"]!: logement,
      noms["garage"]!: garage,
      noms["piscine"]!: piscine,
      noms["jardin"]!: jardin,
    };

    for (final entry in elements.entries) {
      final facteur = facteursEmission[entry.key] ?? 0;
      final duree = dureesAmortissement[entry.key] ?? 1;
      total += (entry.value * facteur) / duree;
    }

    // Ajouter équipements confort
    for (var eq in equipementsConfort) {
      final nom = eq["nom"];
      final quantite =
          double.tryParse(confortControllers[nom]?.text ?? "") ?? 0;
      final facteur = facteursEmission[nom] ?? 0;
      final duree = dureesAmortissement[nom] ?? 1;
      total += (quantite * facteur) / duree;
    }

    setState(() {
      emissionTotale = total;
    });
  }

  Widget champSaisieAvecDetails(
    String label,
    TextEditingController controller,
    String nomPoste,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextField(controller: controller, keyboardType: TextInputType.number),
        const SizedBox(height: 4),
        Text(
          "Facteur : ${facteursEmission[nomPoste]?.toStringAsFixed(2) ?? '...'} kgCO₂ — Durée : ${dureesAmortissement[nomPoste] ?? '...'} ans",
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
              const SizedBox(height: 16),
              champSaisieAvecDetails(
                "Surface logement (m²)",
                surfaceLogementController,
                "Maison Classique",
              ),
              champSaisieAvecDetails(
                "Surface garage (m²)",
                surfaceGarageController,
                "Garage béton",
              ),
              champSaisieAvecDetails(
                "Surface piscine (m²)",
                surfacePiscineController,
                "Piscine extérieure",
              ),
              champSaisieAvecDetails(
                "Surface jardin (m²)",
                surfaceJardinController,
                "Abri de jardin",
              ),
            ],
          ),
        ),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Équipements de confort",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (var eq in equipementsConfort)
                champSaisieAvecDetails(
                  "${eq["nom"]} (${eq["unite"]})",
                  confortControllers[eq["nom"]]!,
                  eq["nom"],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: calculerEmission,
          child: const Text("Calculer émission"),
        ),
        const SizedBox(height: 10),
        Text("Émission estimée : ${emissionTotale.toStringAsFixed(1)} kg CO₂e"),
      ],
    );
  }
}
