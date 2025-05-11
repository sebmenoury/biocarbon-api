import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../data/services/api_service.dart';
import '../../utils/const_construction.dart';

class ConstructionScreen extends StatefulWidget {
  const ConstructionScreen({super.key});

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  final TextEditingController surfaceLogementController =
      TextEditingController();
  final TextEditingController surfaceGarageController = TextEditingController();
  final TextEditingController surfacePiscineLongueurController =
      TextEditingController();
  final TextEditingController surfacePiscineLargeurController =
      TextEditingController();
  final TextEditingController surfaceJardinController = TextEditingController();
  final TextEditingController nbProprietairesController = TextEditingController(
    text: '1',
  );

  Map<String, TextEditingController> confortControllers = {};

  String typeLogement = "Maison Classique";
  String typePiscine = "Piscine béton";
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
    loadEquipementsData();
  }

  Future<void> loadEquipementsData() async {
    try {
      final equipements = await ApiService.getRefEquipements();
      final Map<String, double> facteurs = {};
      final Map<String, int> durees = {};

      for (var e in equipements) {
        final nom = e['Nom_Equipement'];
        final facteur =
            double.tryParse(
              e['Valeur_Emission_Grise'].toString().replaceAll(',', '.'),
            ) ??
            0;
        final duree = int.tryParse(e['Duree_Amortissement'].toString()) ?? 1;
        facteurs[nom] = facteur;
        durees[nom] = duree;
      }

      setState(() {
        facteursEmission = facteurs;
        dureesAmortissement = durees;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Erreur chargement des équipements : $e");
    }
  }

  void calculerEmission() {
    final reduction = reductionParAnnee(anneeConstruction);
    final nbProprio = int.tryParse(nbProprietairesController.text) ?? 1;

    final double logement =
        double.tryParse(surfaceLogementController.text) ?? 0;
    final double garage = double.tryParse(surfaceGarageController.text) ?? 0;
    final double largeurPiscine =
        double.tryParse(surfacePiscineLargeurController.text) ?? 0;
    final double longueurPiscine =
        double.tryParse(surfacePiscineLongueurController.text) ?? 0;
    final double jardin = double.tryParse(surfaceJardinController.text) ?? 0;
    final surfacePiscine = largeurPiscine * longueurPiscine;

    double total = 0;

    total +=
        (logement * (facteursEmission[typeLogement] ?? 0) * reduction) /
        (dureesAmortissement[typeLogement] ?? 1) /
        nbProprio;
    total +=
        (garage * (facteursEmission['Garage béton'] ?? 0) * reduction) /
        (dureesAmortissement['Garage béton'] ?? 1) /
        nbProprio;
    total +=
        (surfacePiscine * (facteursEmission[typePiscine] ?? 0) * reduction) /
        (dureesAmortissement[typePiscine] ?? 1) /
        nbProprio;
    total +=
        (jardin * (facteursEmission['Abri de jardin bois'] ?? 0) * reduction) /
        (dureesAmortissement['Abri de jardin bois'] ?? 1) /
        nbProprio;

    for (var eq in equipementsConfort) {
      final nom = eq["nom"];
      final quantite =
          double.tryParse(confortControllers[nom]?.text ?? "") ?? 0;
      final facteur = facteursEmission[nom] ?? 0;
      final duree = dureesAmortissement[nom] ?? 1;
      total += (quantite * facteur * reduction) / (duree * nbProprio);
    }

    setState(() {
      emissionTotale = total;
    });
  }

  Widget champ(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return BaseScreen(
      title: "Construction du logement",
      children: [
        CustomCard(
          child: Column(
            children: [
              DropdownButton<String>(
                value: typeLogement,
                onChanged: (value) => setState(() => typeLogement = value!),
                items:
                    facteursEmission.keys
                        .where(
                          (k) =>
                              k.startsWith("Maison") ||
                              k.startsWith("Appartement"),
                        )
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
              ),
              champ("Surface logement (m²)", surfaceLogementController),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => anneeConstruction--),
                    icon: const Icon(Icons.remove),
                  ),
                  Text("Année : $anneeConstruction"),
                  IconButton(
                    onPressed: () => setState(() => anneeConstruction++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              champ("Nombre de propriétaires", nbProprietairesController),
              champ("Surface garage (m²)", surfaceGarageController),
              DropdownButton<String>(
                value: typePiscine,
                onChanged: (val) => setState(() => typePiscine = val!),
                items:
                    ["Piscine béton", "Piscine coque"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
              ),
              champ("Longueur piscine (m)", surfacePiscineLongueurController),
              champ("Largeur piscine (m)", surfacePiscineLargeurController),
              champ("Surface abri/serre (m²)", surfaceJardinController),
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
                champ(
                  "${eq["nom"]} (${eq["unite"]})",
                  confortControllers[eq["nom"]]!,
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
