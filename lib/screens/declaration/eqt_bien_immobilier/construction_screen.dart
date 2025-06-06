import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../ui/widgets/custom_dropdown_compact.dart';
import '../../../data/services/api_service.dart';
import '../bien_immobilier/bien_immobilier.dart';
import 'poste_bien_immobilier.dart';
import 'package:flutter/cupertino.dart';
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

  late String selectedPiscineType;

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
    selectedPiscineType = poste.typePiscine;
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

  // ------------------------------------------
  // 🔽 METHODE ROULEAU POUR SELECTION LISTE
  // ------------------------------------------

  Widget buildPiscinePicker() {
    List<String> typesPiscine = ["Piscine béton", "Piscine coque"];

    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder:
              (_) => Container(
                height: 250,
                padding: const EdgeInsets.only(top: 12),
                color: Colors.white,
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: typesPiscine.indexOf(poste.typePiscine)),
                        itemExtent: 32.0,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            poste.typePiscine = typesPiscine[index];
                          });
                        },
                        children: typesPiscine.map((e) => Text(e)).toList(),
                      ),
                    ),
                    TextButton(child: const Text("Fermer", style: TextStyle(fontSize: 12)), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text("Type de piscine", style: TextStyle(fontSize: 11, color: Colors.grey.shade700)), Text(poste.typePiscine, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))],
        ),
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
          Center(child: Text("Construction et rénovations associées au logement", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// DESCRIPTIF DU BIEN
              CustomCard(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: facteursEmission.keys.contains(poste.nomEquipement) ? poste.nomEquipement : null,
                      decoration: const InputDecoration(
                        labelText: "Type de construction",
                        labelStyle: TextStyle(fontSize: 10),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 30),
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
                                    poste.anneeConstruction = (poste.anneeConstruction - 1).clamp(0, 1000);
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
                                        poste.anneeConstruction = parsed;
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
                                    poste.anneeConstruction = (poste.anneeConstruction + 1).clamp(0, 1000);
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
                    const Text("Surface garage (m²)", style: TextStyle(fontSize: 11)),
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
                                poste.surfaceGarage = (poste.surfaceGarage - 1).clamp(0, 1000);
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
                                poste.surfaceGarage = (poste.surfaceGarage + 1).clamp(0, 1000);
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
                                poste.surfacePiscine = (poste.surfacePiscine - 1).clamp(0, 1000);
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
                                poste.surfacePiscine = (poste.surfacePiscine + 1).clamp(0, 1000);
                                piscineController.text = poste.surfacePiscine.toStringAsFixed(0);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildPiscinePicker(),
                  ],
                ),
              ),

              /// ABRI / SERRE
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Surface abri / serre (m²)", style: TextStyle(fontSize: 11)),
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
                                poste.surfaceAbriEtSerre = (poste.surfaceAbriEtSerre - 1).clamp(0, 1000);
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
                                poste.surfaceAbriEtSerre = (poste.surfaceAbriEtSerre + 1).clamp(0, 1000);
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
              const SizedBox(height: 12),

              /// BOUTON
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
                      if (widget.onSave != null) widget.onSave!();
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
