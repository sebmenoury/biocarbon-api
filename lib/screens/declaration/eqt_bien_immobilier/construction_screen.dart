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
  late bool isEdition;

  @override
  void initState() {
    super.initState();
    isEdition = widget.bien.poste.nomEquipement.isNotEmpty;
    loadEquipementsData();
    garageController = TextEditingController(text: poste.surfaceGarage.toStringAsFixed(0));
    surfaceController = TextEditingController(text: poste.surface.toStringAsFixed(0));
    anneeController = TextEditingController(text: poste.anneeConstruction.toString());
    piscineController = TextEditingController(text: poste.surfacePiscine.toStringAsFixed(0));
    abriController = TextEditingController(text: poste.surfaceAbriEtSerre.toStringAsFixed(0));

    if (!isEdition) {
      poste.nomEquipement = "Maison Classique"; // par défaut
      poste.surface = 100;
      poste.anneeConstruction = DateTime.now().year - 10;
      poste.surfaceGarage = 0;
      poste.surfacePiscine = 0;
      poste.typePiscine = "Piscine béton";
      poste.surfaceAbriEtSerre = 0;
    }
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
          Center(child: Text("Construction et rénovations associées au logement", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),

      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// DENTETE TYPE DE BIEN AVEC EMISSION ACTUALISEE
              CustomCard(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [const Icon(Icons.home_work, size: 16), const SizedBox(width: 8), Text(bien.typeBien, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                    Text("${total.toStringAsFixed(0)} kg CO₂/an", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              /// DESCRIPTIF DU BIEN
              CustomCard(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            value: facteursEmission.keys.contains(poste.nomEquipement) ? poste.nomEquipement : null,
                            decoration: const InputDecoration(
                              labelText: "Type de construction",
                              labelStyle: TextStyle(fontSize: 10),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            ),
                            isExpanded: true,
                            style: const TextStyle(fontSize: 11),
                            items:
                                facteursEmission.keys
                                    .where((k) => k.contains("Maison") || k.contains("Appartement"))
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11))))
                                    .toList(),
                            onChanged: (val) => setState(() => poste.nomEquipement = val!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// SURFACE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Surface (m²)", style: TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.surface = (poste.surface - 1).clamp(0, 1000);
                                    surfaceController.text = poste.surface.toStringAsFixed(0);
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: TextFormField(
                                  controller: surfaceController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val);
                                    if (parsed != null) {
                                      setState(() {
                                        poste.surface = parsed;
                                      });
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.surface = (poste.surface + 1).clamp(0, 1000);
                                    surfaceController.text = poste.surface.toStringAsFixed(0);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// ANNÉE DE CONSTRUCTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Année de construction", style: TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.anneeConstruction = (poste.anneeConstruction - 1).clamp(1900, DateTime.now().year);
                                    anneeController.text = poste.anneeConstruction.toStringAsFixed(0);
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: TextFormField(
                                  controller: anneeController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                                  onChanged: (val) {
                                    final parsed = int.tryParse(val);
                                    if (parsed != null) {
                                      setState(() {
                                        poste.anneeConstruction = parsed.clamp(1900, DateTime.now().year);
                                      });
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.anneeConstruction = (poste.anneeConstruction + 1).clamp(1900, DateTime.now().year);
                                    anneeController.text = poste.anneeConstruction.toStringAsFixed(0);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const SizedBox(height: 3),

              /// GARAGE
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Surface garage béton (m²)", style: TextStyle(fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                poste.surfaceGarage = (poste.surfaceGarage - 1).clamp(0, 500);
                                garageController.text = poste.surfaceGarage.toStringAsFixed(0);
                              });
                            },
                          ),
                          SizedBox(
                            width: 40,
                            child: TextFormField(
                              controller: garageController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null) {
                                  setState(() {
                                    poste.surfaceGarage = parsed;
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                poste.surfaceGarage = (poste.surfaceGarage + 1).clamp(0, 500);
                                garageController.text = poste.surfaceGarage.toStringAsFixed(0);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              /// PISCINE
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne surface piscine
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Surface piscine (m²)", style: TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.surfacePiscine = (poste.surfacePiscine - 1).clamp(0, 200);
                                    piscineController.text = poste.surfacePiscine.toStringAsFixed(0);
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: TextFormField(
                                  controller: piscineController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val);
                                    if (parsed != null) {
                                      setState(() {
                                        poste.surfacePiscine = parsed;
                                      });
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.surfacePiscine = (poste.surfacePiscine + 1).clamp(0, 200);
                                    piscineController.text = poste.surfacePiscine.toStringAsFixed(0);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Ligne type de piscine (dropdown)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 180, // ajuste si besoin
                          child: CustomDropdownCompact(
                            value: poste.typePiscine,
                            items: const ["Piscine béton", "Piscine coque"],
                            label: "Type de piscine",
                            onChanged: (val) => setState(() => poste.typePiscine = val ?? ''),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// ABRI / SERRE
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Surface abri / serre bois (m²)", style: TextStyle(fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                poste.surfaceAbriEtSerre = (poste.surfaceAbriEtSerre - 1).clamp(0, 400);
                                abriController.text = poste.surfaceAbriEtSerre.toStringAsFixed(0);
                              });
                            },
                          ),
                          SizedBox(
                            width: 40,
                            child: TextFormField(
                              controller: abriController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null) {
                                  setState(() {
                                    poste.surfaceAbriEtSerre = parsed;
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                poste.surfaceAbriEtSerre = (poste.surfaceAbriEtSerre + 1).clamp(0, 400);
                                abriController.text = poste.surfaceAbriEtSerre.toStringAsFixed(0);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              /// BOUTON
              const SizedBox(height: 24),
              poste.nomEquipement.isNotEmpty
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        onPressed: () async {
                          await ApiService.deleteUCPoste(poste.id!); // 👈 Corrigé
                          if (!mounted) return;
                          Navigator.of(context).pop(); // retour à l'écran précédent
                        },
                        child: const Text("Supprimer", style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final emission = calculerTotalEmission(poste, facteursEmission, dureesAmortissement, nbProprietaires: bien.nbProprietaires);

                          await ApiService.savePoste({
                            "ID_Usage": poste.id,
                            "Code_Individu": "BASILE",
                            "Type_Temps": "Réel",
                            "Valeur_Temps": "2025",
                            "Date_enregistrement": DateTime.now().toIso8601String(),
                            "Type_Poste": "Equipement",
                            "Type_Categorie": "Logement",
                            "Sous_Categorie": "Construction",
                            "Nom_Poste": poste.nomEquipement,
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
                        child: const Text("Mettre à jour", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  )
                  : Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (poste.nomEquipement.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Merci de sélectionner un type de construction')));
                          return;
                        }

                        final emission = calculerTotalEmission(poste, facteursEmission, dureesAmortissement, nbProprietaires: bien.nbProprietaires);

                        await ApiService.savePoste({
                          "Code_Individu": "BASILE",
                          "Type_Temps": "Réel",
                          "Valeur_Temps": "2025",
                          "Date_enregistrement": DateTime.now().toIso8601String(),
                          "Type_Poste": "Equipement",
                          "Type_Categorie": "Logement",
                          "Sous_Categorie": "Construction",
                          "Nom_Poste": poste.nomEquipement,
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
                      child: const Text("Enregistrer", style: TextStyle(fontSize: 12)),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
