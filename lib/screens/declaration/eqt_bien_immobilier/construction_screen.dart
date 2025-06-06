import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../ui/widgets/custom_dropdown_compact.dart';
import '../../../data/services/api_service.dart';
import '../bien_immobilier/bien_immobilier.dart';
import 'poste_bien_immobilier.dart';
import 'emission_calculator_immobilier.dart';

class ConstructionScreen extends StatefulWidget {
  final BienImmobilier bien;
  final VoidCallback onSave;

  const ConstructionScreen({Key? key, required this.bien, required this.onSave}) : super(key: key);

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  Map<String, double> facteursEmission = {};
  Map<String, int> dureesAmortissement = {};
  bool isLoading = true;
  String? errorMsg;

  BienImmobilier get bien => widget.bien;
  PosteBienImmobilier get poste => widget.bien.poste;

  late TextEditingController garageController;
  late TextEditingController surfaceController;
  late TextEditingController anneeController;
  late TextEditingController piscineController;
  late TextEditingController abriController;

  @override
  void initState() {
    super.initState();
    loadEquipementsData();
    garageController = TextEditingController(text: poste.surfaceGarage.toStringAsFixed(0));
    surfaceController = TextEditingController(text: poste.surface.toStringAsFixed(0));
    anneeController = TextEditingController(text: poste.anneeConstruction.toString());
    piscineController = TextEditingController(text: poste.surfacePiscine.toStringAsFixed(0));
    abriController = TextEditingController(text: poste.surfaceAbriEtSerre.toStringAsFixed(0));
  }

  @override
  void dispose() {
    garageController.dispose();
    surfaceController.dispose();
    anneeController.dispose();
    piscineController.dispose();
    abriController.dispose();
    super.dispose();
  }

  Future<void> loadEquipementsData() async {
    try {
      final equipements = await ApiService.getRefEquipements();
      final Map<String, double> facteurs = {};
      final Map<String, int> durees = {};

      for (var e in equipements) {
        final nom = e['Nom_Equipement'];
        final facteur = double.tryParse(e['Valeur_Emission_Grise'].toString().replaceAll(',', '.')) ?? 0;
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
      setState(() {
        errorMsg = "Erreur lors du chargement des équipements";
        isLoading = false;
      });
    }
  }

  Widget buildInputCard(String label, TextEditingController controller, void Function() onMinus, void Function() onPlus) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.remove), iconSize: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: onMinus),
                SizedBox(
                  width: 40,
                  child: TextFormField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() {
                          if (controller == garageController) poste.surfaceGarage = parsed;
                          if (controller == surfaceController) poste.surface = parsed;
                          if (controller == piscineController) poste.surfacePiscine = parsed;
                          if (controller == abriController) poste.surfaceAbriEtSerre = parsed;
                        });
                      }
                    },
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), iconSize: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = calculerTotalEmission(poste, facteursEmission, dureesAmortissement, nbProprietaires: bien.nbProprietaires);

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMsg != null) {
      return Scaffold(body: Center(child: Text(errorMsg!, style: const TextStyle(color: Colors.red))));
    }

    return BaseScreen(
      title: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          const Text("Construction et rénovations associées au logement", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CustomCard(
                padding: const EdgeInsets.all(12),
                child: CustomDropdownCompact(
                  value: poste.nomEquipement,
                  items: facteursEmission.keys.where((k) => k.contains("Maison") || k.contains("Appartement")).toList(),
                  label: "Type de construction",
                  onChanged: (val) => setState(() => poste.nomEquipement = val ?? poste.nomEquipement),
                ),
              ),
              const SizedBox(height: 8),
              buildInputCard(
                "Surface (m²)",
                surfaceController,
                () => setState(() {
                  poste.surface = (poste.surface - 1).clamp(0, 10000);
                  surfaceController.text = poste.surface.toStringAsFixed(0);
                }),
                () => setState(() {
                  poste.surface = (poste.surface + 1).clamp(0, 10000);
                  surfaceController.text = poste.surface.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 3),
              buildInputCard(
                "Année de construction",
                anneeController,
                () => setState(() {
                  poste.anneeConstruction = (poste.anneeConstruction - 1).clamp(1800, DateTime.now().year);
                  anneeController.text = poste.anneeConstruction.toString();
                }),
                () => setState(() {
                  poste.anneeConstruction = (poste.anneeConstruction + 1).clamp(1800, DateTime.now().year);
                  anneeController.text = poste.anneeConstruction.toString();
                }),
              ),
              const SizedBox(height: 3),
              buildInputCard(
                "Surface garage (m²)",
                garageController,
                () => setState(() {
                  poste.surfaceGarage = (poste.surfaceGarage - 1).clamp(0, 1000);
                  garageController.text = poste.surfaceGarage.toStringAsFixed(0);
                }),
                () => setState(() {
                  poste.surfaceGarage = (poste.surfaceGarage + 1).clamp(0, 1000);
                  garageController.text = poste.surfaceGarage.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 3),
              buildInputCard(
                "Surface piscine (m²)",
                piscineController,
                () => setState(() {
                  poste.surfacePiscine = (poste.surfacePiscine - 1).clamp(0, 500);
                  piscineController.text = poste.surfacePiscine.toStringAsFixed(0);
                }),
                () => setState(() {
                  poste.surfacePiscine = (poste.surfacePiscine + 1).clamp(0, 500);
                  piscineController.text = poste.surfacePiscine.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 3),
              CustomCard(
                padding: const EdgeInsets.all(12),
                child: CustomDropdownCompact(
                  value: poste.typePiscine,
                  items: const ["Piscine béton", "Piscine coque"],
                  label: "Type de piscine",
                  onChanged: (val) => setState(() => poste.typePiscine = val ?? poste.typePiscine),
                ),
              ),
              const SizedBox(height: 3),
              buildInputCard(
                "Surface abri / serre (m²)",
                abriController,
                () => setState(() {
                  poste.surfaceAbriEtSerre = (poste.surfaceAbriEtSerre - 1).clamp(0, 200);
                  abriController.text = poste.surfaceAbriEtSerre.toStringAsFixed(0);
                }),
                () => setState(() {
                  poste.surfaceAbriEtSerre = (poste.surfaceAbriEtSerre + 1).clamp(0, 200);
                  abriController.text = poste.surfaceAbriEtSerre.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final double emission = calculerTotalEmission(poste, facteursEmission, dureesAmortissement, nbProprietaires: bien.nbProprietaires);
                      await ApiService.savePoste({
                        "Code_Individu": "BASILE",
                        "Type_Temps": "Réel",
                        "Valeur_Temps": "2025",
                        "Date_enregistrement": DateTime.now().toIso8601String(),
                        "Type_Poste": "Equipement",
                        "Type_Categorie": "Logement",
                        "Sous_Categorie": "Habitat",
                        "Nom_Poste": poste.nomEquipement,
                        "Nom_Logement": bien.nomLogement,
                        "Quantite": poste.surface,
                        "Unite": "m²",
                        "Facteur_Emission": facteursEmission[poste.nomEquipement],
                        "Emission_Calculee": emission,
                        "Mode_Calcul": "Amorti",
                        "Annee_Achat": poste.anneeConstruction,
                        "Duree_Amortissement": dureesAmortissement[poste.nomEquipement],
                      });

                      if (!mounted) return;
                      widget.onSave();
                      Navigator.of(context).pop();
                    },
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
          ),
        ),
      ],
    );
  }
}
