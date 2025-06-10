import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../ui/widgets/custom_dropdown_compact.dart';
import '../../../data/services/api_service.dart';
import '../bien_immobilier/bien_immobilier.dart';
import 'poste_bien_immobilier.dart';
import 'emission_calculator_immobilier.dart';
import 'const_construction.dart';

class ConstructionScreen extends StatefulWidget {
  final String idBien;
  final VoidCallback onSave;

  const ConstructionScreen({Key? key, required this.idBien, required this.onSave}) : super(key: key);

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  Map<String, double> facteursEmission = {};
  Map<String, int> dureesAmortissement = {};
  bool isLoading = true;
  String? errorMsg;

  late BienImmobilier bien;
  bool bienCharge = false;

  PosteBienImmobilier get poste => bien.poste;

  late TextEditingController garageController;
  late TextEditingController surfaceController;
  late TextEditingController anneeController;
  late TextEditingController piscineController;
  late TextEditingController abriController;
  late TextEditingController anneeGarageController;
  late TextEditingController anneePiscineController;
  late TextEditingController anneeAbriController;

  @override
  void initState() {
    super.initState();
    loadEquipementsData();
    loadBienComplet();
  }

  void enregistrerOuMettreAJour() async {
    try {
      final maintenant = DateTime.now().toIso8601String();
      final codeIndividu = "BASILE";
      final typeTemps = "Réel";
      final valeurTemps = "2025";
      const typePoste = "Equipement";
      const typeCategorie = "Logement";
      const sousCategorie = "Construction";

      List<Map<String, dynamic>> postesAEnregistrer = [];

      void ajouterPoste(String nom, double surface, int annee) {
        if (surface > 0 && facteursEmission.containsKey(nom)) {
          final emission = calculerEmissionUnitaire(surface, facteursEmission[nom]!, dureesAmortissement[nom], annee, bien.nbProprietaires);

          final idUsage = "${bien.idBien}_Construction_${nom}_${bien.nomLogement}".replaceAll(' ', '_');

          final posteMap = {
            "ID_Usage": idUsage,
            "Code_Individu": codeIndividu,
            "Type_Temps": typeTemps,
            "Valeur_Temps": valeurTemps,
            "Date_enregistrement": maintenant,
            "ID_Bien": bien.idBien,
            "Type_Bien": bien.typeBien,
            "Type_Poste": typePoste,
            "Type_Categorie": typeCategorie,
            "Sous_Categorie": sousCategorie,
            "Nom_Poste": nom,
            "Nom_Logement": bien.nomLogement,
            "Quantite": surface,
            "Unite": "m²",
            "Frequence": "",
            "Facteur_Emission": facteursEmission[nom],
            "Emission_Calculee": emission,
            "Mode_Calcul": "Amorti",
            "Annee_Achat": annee,
            "Duree_Amortissement": dureesAmortissement[nom],
          };

          print("📦 Poste à enregistrer : $posteMap");
          postesAEnregistrer.add(posteMap);
        } else {
          print("⛔ Ignoré : surface=$surface ou facteur manquant pour '$nom'");
        }
      }

      ajouterPoste(poste.nomEquipement, poste.surface, poste.anneeConstruction);
      ajouterPoste("Garage béton", poste.surfaceGarage, poste.anneeGarage);
      ajouterPoste(poste.typePiscine, poste.surfacePiscine, poste.anneePiscine);
      ajouterPoste("Abri de jardin bois", poste.surfaceAbriEtSerre, poste.anneeAbri);

      for (final p in postesAEnregistrer) {
        print("📤 Envoi API : ${p['ID_Usage']} (${p['Nom_Poste']})");
        await ApiService.saveOrUpdatePoste(p);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Enregistrement effectué")));
      widget.onSave();
      Navigator.of(context).pop();
    } catch (e) {
      print('❌ Erreur enregistrement : $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Erreur lors de l'enregistrement")));
    }
  }

  void supprimerPoste() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmer la suppression"),
            content: const Text("Souhaitez-vous vraiment supprimer ce poste ?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
            ],
          ),
    );

    if (confirm == true && poste.id != null) {
      try {
        await ApiService.deleteUCPoste(poste.id!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Poste supprimé")));
        widget.onSave();
        Navigator.of(context).pop();
      } catch (e) {
        print('❌ Erreur suppression : \$e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Erreur lors de la suppression du poste")));
      }
    }
  }

  Future<void> loadBienComplet() async {
    try {
      // 🔹 1. Charger le bien par ID
      final biens = await ApiService.getBiens("BASILE");
      final bienData = biens.firstWhere((b) => b['ID_Bien'] == widget.idBien, orElse: () => {});

      if (bienData.isEmpty) throw Exception("Bien introuvable");

      final nomLogement = (bienData['Dénomination'] ?? '').toString().trim();
      final typeBien = bienData['Type_Bien'] ?? 'Logement principal';
      final nbProp = int.tryParse(bienData['Nb_Proprietaires'].toString()) ?? 1;
      final nbHabitants = double.tryParse(bienData['Nb_Habitants'].toString()) ?? 1;

      debugPrint("✅ Bien trouvé : $nomLogement ($widget.idBien)");

      // 🔹 2. Récupérer tous les postes de l'utilisateur pour l'année
      final postes = await ApiService.getUCPostes("BASILE", "2025");

      // 🔹 3. Filtrer les postes liés à ce bien
      final postesConstruction = postes.where((p) => (p['ID_Bien']?.toString() ?? '') == widget.idBien && p['Sous_Categorie'] == 'Construction').toList();

      PosteBienImmobilier poste = PosteBienImmobilier();

      if (postesConstruction.isNotEmpty) {
        debugPrint("🏗 ${postesConstruction.length} postes Construction trouvés pour ce bien");

        for (final p in postesConstruction) {
          final nom = p['Nom_Poste'] ?? '';
          final quantite = double.tryParse(p['Quantite'].toString()) ?? 0;
          final annee = int.tryParse(p['Annee_Achat'].toString()) ?? 2010;

          if (nom.contains('Maison') || nom.contains('Appartement')) {
            poste.id = p['ID_Usage'];
            poste.nomEquipement = nom;
            poste.nomLogement = nomLogement;
            poste.surface = quantite;
            poste.anneeConstruction = annee;
            poste.typeBien = typeBien;
          } else if (nom.contains('Garage')) {
            poste.surfaceGarage = quantite;
            poste.anneeGarage = annee;
          } else if (nom.contains('Abri')) {
            poste.surfaceAbriEtSerre = quantite;
            poste.anneeAbri = annee;
          } else if (nom.contains('Piscine')) {
            poste.surfacePiscine = quantite;
            poste.typePiscine = nom;
            poste.anneePiscine = annee;
          }
        }
      } else {
        debugPrint("⚠️ Aucun poste Construction trouvé pour ce bien. Initialisation par défaut.");
        poste.nomEquipement = "Maison Classique";
        poste.surface = 0;
        poste.anneeConstruction = DateTime.now().year - 10;
        poste.surfaceGarage = 0;
        poste.surfacePiscine = 0;
        poste.typePiscine = "Piscine béton";
        poste.surfaceAbriEtSerre = 0;
      }

      // 🔹 4. Créer le bien final
      bien = BienImmobilier(idBien: widget.idBien, nomLogement: nomLogement, typeBien: typeBien, nbProprietaires: nbProp, nbHabitants: nbHabitants, poste: poste);

      // 🔹 5. Initialiser les contrôleurs
      garageController = TextEditingController(text: poste.surfaceGarage.toStringAsFixed(0));
      surfaceController = TextEditingController(text: poste.surface.toStringAsFixed(0));
      anneeController = TextEditingController(text: poste.anneeConstruction.toString());
      piscineController = TextEditingController(text: poste.surfacePiscine.toStringAsFixed(0));
      abriController = TextEditingController(text: poste.surfaceAbriEtSerre.toStringAsFixed(0));
      anneeGarageController = TextEditingController(text: poste.anneeGarage.toString());
      anneePiscineController = TextEditingController(text: poste.anneePiscine.toString());
      anneeAbriController = TextEditingController(text: poste.anneeAbri.toString());

      // Sécurisation du type de construction
      final typesConstruction = facteursEmission.keys.where((k) => k.contains("Maison") || k.contains("Appartement")).toList();

      if (!typesConstruction.contains(poste.nomEquipement)) {
        poste.nomEquipement = typesConstruction.contains("Maison Classique") ? "Maison Classique" : (typesConstruction.isNotEmpty ? typesConstruction.first : "");
      }

      // Sécurisation du type de piscine
      final typesPiscine = ["Piscine béton", "Piscine coque"];
      if (!typesPiscine.contains(poste.typePiscine)) {
        poste.typePiscine = "Piscine béton";
      }

      setState(() {
        bienCharge = true;
      });
    } catch (e) {
      debugPrint("❌ Erreur chargement du bien complet : $e");
      setState(() {
        errorMsg = "Erreur lors du chargement du bien.";
        isLoading = false;
      });
    }
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

  double calculerEmissionUnitaire(double surface, double facteur, int? duree, int annee, int nbProprietaires) {
    final anneeCourante = DateTime.now().year;
    final age = anneeCourante - annee;
    final dureeAmortie = duree ?? 1;

    if (age >= dureeAmortie) {
      return 0; // 🔴 Bien totalement amorti
    }

    final reduction = reductionParAnnee(annee);
    return (surface * facteur * reduction) / dureeAmortie / nbProprietaires;
  }

  @override
  void dispose() {
    garageController.dispose();
    surfaceController.dispose();
    anneeController.dispose();
    piscineController.dispose();
    abriController.dispose();
    anneeGarageController.dispose();
    anneePiscineController.dispose();
    anneeAbriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!bienCharge || isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMsg != null) {
      return Scaffold(body: Center(child: Text(errorMsg!, style: TextStyle(color: Colors.red))));
    }
    final total = calculerTotalEmission(poste, facteursEmission, dureesAmortissement, nbProprietaires: bien.nbProprietaires);
    final List<String> typesPiscine = ["Piscine béton", "Piscine coque"];

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// DENTETE TYPE DE BIEN AVEC EMISSION ACTUALISEE
              CustomCard(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [const Icon(Icons.home_work, size: 16), const SizedBox(width: 8), Text(bien.nomLogement, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
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
                          decoration: BoxDecoration(color: (poste.surface > 0) ? Colors.white : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),

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
                                  onChanged: (String? val) {
                                    final parsed = double.tryParse(val ?? '');
                                    setState(() {
                                      poste.surface = parsed != null && parsed >= 0 ? parsed : 0;
                                    });
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
                          decoration: BoxDecoration(color: (poste.surface > 0) ? Colors.white : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
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
                                  onChanged: (String? val) {
                                    final parsed = int.tryParse(val ?? '');
                                    setState(() {
                                      poste.anneeConstruction = (parsed != null ? parsed : 1900).clamp(1900, DateTime.now().year);
                                    });
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Surface garage béton (m²)", style: TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: (poste.surfaceGarage > 0) ? Colors.white : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
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
                                  onChanged: (String? val) {
                                    final parsed = double.tryParse(val ?? '');
                                    setState(() {
                                      poste.surfaceGarage = parsed != null && parsed >= 0 ? parsed : 0;
                                    });
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
                    const SizedBox(height: 12),

                    /// ANNÉE DE CONSTRUCTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Année de construction", style: TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: (poste.surfaceGarage > 0) ? Colors.white : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.anneeGarage = (poste.anneeGarage - 1).clamp(1900, DateTime.now().year);
                                    anneeGarageController.text = poste.anneeGarage.toStringAsFixed(0);
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: TextFormField(
                                  controller: anneeGarageController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                                  onChanged: (String? val) {
                                    final parsed = int.tryParse(val ?? '');
                                    setState(() {
                                      poste.anneeGarage = (parsed != null ? parsed : 1900).clamp(1900, DateTime.now().year);
                                    });
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
                                    poste.anneeGarage = (poste.anneeGarage + 1).clamp(1900, DateTime.now().year);
                                    anneeGarageController.text = poste.anneeGarage.toStringAsFixed(0);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          decoration: BoxDecoration(color: (poste.surfacePiscine > 0) ? Colors.white : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
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

                    /// ANNÉE DE CONSTRUCTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Année de construction", style: TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: (poste.surfacePiscine > 0) ? Colors.white : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.anneePiscine = (poste.anneePiscine - 1).clamp(1900, DateTime.now().year);
                                    anneePiscineController.text = poste.anneePiscine.toStringAsFixed(0);
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: TextFormField(
                                  controller: anneePiscineController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                                  onChanged: (val) {
                                    final parsed = int.tryParse(val);
                                    setState(() {
                                      poste.anneePiscine = parsed != null && parsed >= 1900 ? parsed.clamp(1900, DateTime.now().year) : 1900;
                                    });
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
                                    poste.anneePiscine = (poste.anneePiscine + 1).clamp(1900, DateTime.now().year);
                                    anneePiscineController.text = poste.anneePiscine.toStringAsFixed(0);
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
                            value: typesPiscine.contains(poste.typePiscine) ? poste.typePiscine : typesPiscine.first,
                            items: typesPiscine,
                            label: "Type de piscine",
                            onChanged: (val) {
                              double? parsed = val != null ? double.tryParse(val) : null;
                              setState(() {
                                poste.surfacePiscine = parsed != null && parsed >= 0 ? parsed : 0;
                              });
                            },
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Surface abri / serre bois (m²)", style: TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: (poste.surfaceAbriEtSerre > 0) ? Colors.white : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
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
                                  onChanged: (String? val) {
                                    final parsed = double.tryParse(val ?? '');
                                    setState(() {
                                      poste.surfaceAbriEtSerre = parsed != null && parsed >= 0 ? parsed : 0;
                                    });
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
                    const SizedBox(height: 12),

                    /// ANNÉE DE CONSTRUCTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Année de construction", style: TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: (poste.surfaceAbriEtSerre > 0) ? Colors.white : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    poste.anneeAbri = (poste.anneeAbri - 1).clamp(1900, DateTime.now().year);
                                    anneeAbriController.text = poste.anneeAbri.toStringAsFixed(0);
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: TextFormField(
                                  controller: anneeAbriController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                                  onChanged: (String? val) {
                                    final parsed = int.tryParse(val ?? '');
                                    setState(() {
                                      poste.anneeAbri = (parsed != null ? parsed : 1900).clamp(1900, DateTime.now().year);
                                    });
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
                                    poste.anneeAbri = (poste.anneeAbri + 1).clamp(1900, DateTime.now().year);
                                    anneeAbriController.text = poste.anneeAbri.toStringAsFixed(0);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              /// BOUTON
              const SizedBox(height: 24),
              poste.id != null
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        onPressed: supprimerPoste,
                        child: const Text("Supprimer", style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                      ElevatedButton(onPressed: enregistrerOuMettreAJour, child: const Text("Mettre à jour", style: TextStyle(fontSize: 12))),
                    ],
                  )
                  : Center(child: ElevatedButton(onPressed: enregistrerOuMettreAJour, child: const Text("Enregistrer", style: TextStyle(fontSize: 12)))),
            ],
          ),
        ),
      ],
    );
  }
}
