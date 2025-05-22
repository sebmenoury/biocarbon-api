import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../eqt_bien_immobilier/bien_immobilier.dart';
import '../eqt_bien_immobilier/poste_bien_immobilier.dart';
import '../eqt_bien_immobilier/emission_calculator_immobilier.dart';

class ConstructionScreen extends StatefulWidget {
  final BienImmobilier bien;
  final VoidCallback? onSave;

  const ConstructionScreen({super.key, required this.bien, this.onSave});

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

  bool showGarage = false;
  bool showPiscine = false;
  bool showAbri = false;

  @override
  void initState() {
    super.initState();
    loadEquipementsData();
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
    final total = calculerTotalEmission(poste, facteursEmission, dureesAmortissement);

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMsg != null) {
      return Scaffold(body: Center(child: Text(errorMsg!, style: const TextStyle(color: Colors.red))));
    }

    return BaseScreen(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 18,
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Text("Bien immobilier", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),

      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// INFOS DU BIEN IMMOBILIER (fusionné)
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Ligne type de bien + émission
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(sousCategorieIcons['Biens Immobiliers'] ?? Icons.home, size: 12),
                            const SizedBox(width: 8),
                            Text(bien.typeBien, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        Text("${total.toStringAsFixed(0)} kgCO₂/an", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 8),

                    /// Dénomination
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text("Dénomination", style: TextStyle(fontSize: 11))),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: bien.nomLogement,
                            onChanged: (val) => bien.nomLogement = val,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.only(bottom: 6),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// Adresse
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text("Adresse", style: TextStyle(fontSize: 11))),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: bien.adresse ?? '',
                            onChanged: (val) => bien.adresse = val,
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.only(bottom: 6),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// Inclure dans le bilan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: 0.75,
                          child: Checkbox(
                            value: bien.inclureDansBilan ?? true,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) => setState(() => bien.inclureDansBilan = v ?? true),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text("Inclure dans le bilan", style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              /// DESCRIPTIF DU BIEN
              CustomCard(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: facteursEmission.keys.contains(poste.nomEquipement) ? poste.nomEquipement : null,
                      decoration: const InputDecoration(
                        labelText: "Type de maison/appartement",
                        labelStyle: TextStyle(fontSize: 10),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11),
                      items:
                          facteursEmission.keys
                              .where((k) => k.contains("Maison") || k.contains("Appartement"))
                              .map(
                                (t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11))),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => poste.nomEquipement = val!),
                    ),
                    const SizedBox(height: 12),

                    /// SURFACE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Surface (m²)", style: TextStyle(fontSize: 11)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              iconSize: 11,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed:
                                  () => setState(() {
                                    poste.surface = (poste.surface - 1).clamp(0, 10000); // limite basse 0
                                  }),
                            ),
                            SizedBox(
                              width: 40,
                              child: TextFormField(
                                initialValue: poste.surface.toStringAsFixed(0),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  border: InputBorder.none, // Supprime le trait
                                ),
                                onChanged: (val) {
                                  final parsed = double.tryParse(val);
                                  if (parsed != null) setState(() => poste.surface = parsed);
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              iconSize: 11,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed:
                                  () => setState(() {
                                    poste.surface = (poste.surface + 1).clamp(0, 10000);
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// ANNÉE DE CONSTRUCTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Année de construction", style: TextStyle(fontSize: 11)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              iconSize: 11,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed:
                                  () => setState(() {
                                    poste.anneeConstruction = (poste.anneeConstruction - 1).clamp(
                                      1800,
                                      DateTime.now().year,
                                    );
                                  }),
                            ),
                            SizedBox(
                              width: 50,
                              child: TextFormField(
                                initialValue: poste.anneeConstruction.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  border: InputBorder.none, // Supprime le trait
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed != null) setState(() => poste.anneeConstruction = parsed);
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              iconSize: 11,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed:
                                  () => setState(() {
                                    poste.anneeConstruction = (poste.anneeConstruction + 1).clamp(
                                      1800,
                                      DateTime.now().year,
                                    );
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Nombre de propriétaires", style: TextStyle(fontSize: 11)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              iconSize: 11,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed:
                                  () => setState(() {
                                    if (poste.nbProprietaires > 1) poste.nbProprietaires--;
                                  }),
                            ),
                            SizedBox(
                              width: 40,
                              child: TextFormField(
                                initialValue: poste.nbProprietaires.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                  border: InputBorder.none,
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed != null && parsed >= 1) {
                                    setState(() => poste.nbProprietaires = parsed);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              iconSize: 11,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed:
                                  () => setState(() {
                                    poste.nbProprietaires++;
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 3),

              /// GARAGE
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      title: const Text("Déclarer un garage", style: TextStyle(fontSize: 12)),
                      trailing: Icon(showGarage ? Icons.expand_less : Icons.chevron_right, size: 12),
                      onTap: () => setState(() => showGarage = !showGarage),
                    ),
                    if (showGarage)
                      /// SURFACE GARAGE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Surface garage (m²)", style: TextStyle(fontSize: 11)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                iconSize: 12,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed:
                                    () => setState(() {
                                      poste.surfaceGarage = (poste.surfaceGarage - 1).clamp(0, 500);
                                    }),
                              ),
                              SizedBox(
                                width: 50,
                                child: TextFormField(
                                  initialValue: poste.surfaceGarage.toStringAsFixed(0),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    border: InputBorder.none, // Supprime le trait
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val);
                                    if (parsed != null) setState(() => poste.surfaceGarage = parsed);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                iconSize: 12,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed:
                                    () => setState(() {
                                      poste.surfaceGarage = (poste.surfaceGarage + 1).clamp(0, 500);
                                    }),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              /// PISCINE
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      title: const Text("Déclarer une piscine", style: TextStyle(fontSize: 12)),
                      trailing: Icon(showPiscine ? Icons.expand_less : Icons.chevron_right, size: 12),
                      onTap: () => setState(() => showPiscine = !showPiscine),
                    ),
                    if (showPiscine)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: poste.typePiscine,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "Type de piscine",
                              labelStyle: TextStyle(fontSize: 10),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            ),
                            style: const TextStyle(fontSize: 11),
                            items:
                                ["Piscine béton", "Piscine coque"]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ), // <-- réduit l'espacement vertical
                                          child: Text(t, style: const TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) => setState(() => poste.typePiscine = val!),
                          ),

                          /// LONGUEUR PISCINE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Longueur (m)", style: TextStyle(fontSize: 11)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    iconSize: 12,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed:
                                        () => setState(() {
                                          poste.piscineLongueur = (poste.piscineLongueur - 0.2).clamp(0, 50);
                                        }),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: TextFormField(
                                      initialValue: poste.piscineLongueur.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        border: InputBorder.none, // Supprime le trait
                                      ),
                                      onChanged: (val) {
                                        final parsed = double.tryParse(val);
                                        if (parsed != null) setState(() => poste.piscineLongueur = parsed);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    iconSize: 12,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed:
                                        () => setState(() {
                                          poste.piscineLongueur = (poste.piscineLongueur + 0.2).clamp(0, 50);
                                        }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          /// LARGEUR PISCINE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Largeur (m)", style: TextStyle(fontSize: 11)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    iconSize: 12,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed:
                                        () => setState(() {
                                          poste.piscineLargeur = (poste.piscineLargeur - 0.1).clamp(0, 50);
                                        }),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: TextFormField(
                                      initialValue: poste.piscineLargeur.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        border: InputBorder.none, // Supprime le trait
                                      ),
                                      onChanged: (val) {
                                        final parsed = double.tryParse(val);
                                        if (parsed != null) setState(() => poste.piscineLargeur = parsed);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    iconSize: 12,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed:
                                        () => setState(() {
                                          poste.piscineLargeur = (poste.piscineLargeur + 0.1).clamp(0, 50);
                                        }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              /// ABRI / SERRE
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      title: const Text("Déclarer abri / serre", style: TextStyle(fontSize: 12)),
                      trailing: Icon(showAbri ? Icons.expand_less : Icons.chevron_right, size: 12),
                      onTap: () => setState(() => showAbri = !showAbri),
                    ),
                    if (showAbri)
                      /// SURFACE ABRI / SERRE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Surface abri / serre (m²)", style: TextStyle(fontSize: 11)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                iconSize: 12,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed:
                                    () => setState(() {
                                      poste.surfaceAbriEtSerre = (poste.surfaceAbriEtSerre - 1).clamp(0, 200);
                                    }),
                              ),
                              SizedBox(
                                width: 50,
                                child: TextFormField(
                                  initialValue: poste.surfaceAbriEtSerre.toStringAsFixed(0),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    border: InputBorder.none, // Supprime le trait
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val);
                                    if (parsed != null) setState(() => poste.surfaceAbriEtSerre = parsed);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                iconSize: 12,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed:
                                    () => setState(() {
                                      poste.surfaceAbriEtSerre = (poste.surfaceAbriEtSerre + 1).clamp(0, 200);
                                    }),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              /// BOUTON
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final double emission = calculerTotalEmission(poste, facteursEmission, dureesAmortissement);
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
