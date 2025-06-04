import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../core/constants/app_icons.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../ui/widgets/post_list_section_card.dart';
import '../../data/services/api_service.dart';
import '../../data/classes/poste_postes.dart';
import 'sous_categorie_avec_bien.dart';
import 'bien_immobilier/bien_immobilier.dart';
import 'eqt_bien_immobilier/poste_bien_immobilier.dart';
import 'eqt_bien_immobilier/construction_screen.dart';
import 'eqt_vehicules/vehicule_screen.dart';
import '../../core/constants/app_titre_categorie.dart';
import 'navigation_registry.dart';

class PosteListScreen extends StatefulWidget {
  final String typeCategorie;
  final String sousCategorie;
  final String codeIndividu;
  final String valeurTemps;
  final VoidCallback? onAddPressed;

  const PosteListScreen({super.key, required this.typeCategorie, required this.sousCategorie, required this.codeIndividu, required this.valeurTemps, this.onAddPressed});

  @override
  State<PosteListScreen> createState() => _PosteListScreenState();
}

// ---------------------------------------------------------------
// Gestion des cas particuliers pour Alimentation et Services publics
// ---------------------------------------------------------------

class _PosteListScreenState extends State<PosteListScreen> {
  late Future<List<Poste>> postesFuture;
  late Future<List<Map<String, dynamic>>> biensFuture;
  bool avecBien = false;

  final Map<String, String> sousCategorieRedirigeeParType = {"Alimentation": "Alimentation", "Services publics": "Services publics"};

  @override
  void initState() {
    super.initState();
    avecBien = sousCategoriesAvecBien.contains(widget.sousCategorie);

    if (sousCategorieRedirigeeParType.containsKey(widget.sousCategorie)) {
      postesFuture = ApiService.getPostesByCategorie(sousCategorieRedirigeeParType[widget.sousCategorie]!, widget.codeIndividu, widget.valeurTemps);
    } else {
      postesFuture = ApiService.getPostesBysousCategorie(widget.sousCategorie, widget.codeIndividu, widget.valeurTemps);
    }

    if (avecBien) {
      biensFuture = ApiService.getBiens(widget.codeIndividu).then((biens) => biens.cast<Map<String, dynamic>>());
    }
  }

  // ---------------------------------------------------------------
  // Intialisation des valeurs pour construction screen à remplacer
  // ---------------------------------------------------------------
  void handleAdd([String? idBien]) {
    final nouveauPoste = PosteBienImmobilier(
      nomEquipement: '',
      surface: 100,
      anneeConstruction: 2010,
      nbProprietaires: 1,
      garage: false,
      surfaceGarage: 0,
      piscine: false,
      typePiscine: "Piscine béton",
      piscineLongueur: 4,
      piscineLargeur: 2.5,
      abriEtSerre: false,
      surfaceAbriEtSerre: 0,
    );

    final nouveauBien = BienImmobilier(idBien: idBien, typeBien: 'Logement principal', nomLogement: '', adresse: '', inclureDansBilan: true, poste: nouveauPoste);

    Navigator.push(context, MaterialPageRoute(builder: (context) => ConstructionScreen(bien: nouveauBien, onSave: () => setState(() {}))));
  }

  bool isNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.sousCategorie == "Véhicules" && !isNavigated) {
      isNavigated = true;
      postesFuture.then((postes) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (postes.isEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiculeScreen()));
          }
        });
      });
    }
  }

  // ---------------------------------------------------------------
  // Intialisation des valeurs pour construction screen à remplacer
  // ---------------------------------------------------------------

  void openConstructionScreen(Map<String, dynamic> bien) {
    final poste = PosteBienImmobilier(
      nomEquipement: bien['Nom_Equipement'] ?? '',
      surface: double.tryParse(bien['Surface']?.toString() ?? '100') ?? 100,
      anneeConstruction: int.tryParse(bien['Annee_Construction']?.toString() ?? '2000') ?? 2000,
      nbProprietaires: int.tryParse(bien['Nb_Proprietaires']?.toString() ?? '2') ?? 2,
      garage: bien['Garage'] == true,
      surfaceGarage: double.tryParse(bien['Surface_Garage']?.toString() ?? '0') ?? 0,
      piscine: bien['Piscine'] == true,
      typePiscine: bien['Type_Piscine'] ?? "Piscine béton",
      piscineLongueur: double.tryParse(bien['Piscine_Longueur']?.toString() ?? '0') ?? 0,
      piscineLargeur: double.tryParse(bien['Piscine_Largeur']?.toString() ?? '0') ?? 0,
      abriEtSerre: bien['AbriEtSerre'] == true,
      surfaceAbriEtSerre: double.tryParse(bien['Surface_AbriEtSerre']?.toString() ?? '0') ?? 0,
    );

    final bienObj = BienImmobilier(
      idBien: bien['ID_Bien'],
      typeBien: bien['Type_Bien'] ?? '',
      nomLogement: bien['Dénomination'] ?? '',
      adresse: bien['Adresse'] ?? '',
      inclureDansBilan: bien['Inclure_dans_Bilan'] == true,
      poste: poste,
    );

    Navigator.push(context, MaterialPageRoute(builder: (context) => ConstructionScreen(bien: bienObj, onSave: () => setState(() {}))));
  }

  @override
  Widget build(BuildContext context) {
    final icon = sousCategorieIcons[widget.sousCategorie] ?? Icons.help_outline;
    final color = souscategoryColors[widget.sousCategorie] ?? Colors.grey;

    return BaseScreen(
      // ----------------------------------------------------
      // Affichage des titres et icônes
      // ----------------------------------------------------
      title: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: Text(titreParSousCategorie[widget.sousCategorie] ?? widget.sousCategorie, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ),
        ],
      ),

      children: [
        FutureBuilder<List<Poste>>(
          future: postesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasError) {
              return Padding(padding: const EdgeInsets.all(16), child: Text("Erreur : ${snapshot.error}"));
            }

            final postes = snapshot.data ?? [];

            // ----------------------------------------------------
            // Cas particulier pour les véhicules et l'alimentation
            // ----------------------------------------------------

            if (!avecBien && widget.sousCategorie == "Véhicules" || widget.typeCategorie == "Alimentation") {
              final Map<String, List<Poste>> postesParSousCat = {};
              for (var poste in postes) {
                final key = poste.sousCategorie;
                if (!postesParSousCat.containsKey(key)) {
                  postesParSousCat[key] = [];
                }
                postesParSousCat[key]!.add(poste);
              }

              // Affichage par sous-catégorie
              return Column(
                children:
                    postesParSousCat.entries.map((entry) {
                      final sousCat = entry.key;
                      final postes = entry.value;
                      final total = postes.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));

                      postes.sort((a, b) => (b.emissionCalculee ?? 0).compareTo(a.emissionCalculee ?? 0));

                      return PostListSectionCard(
                        sousCat: sousCat,
                        postes: postes,
                        total: total,
                        onTap: () {
                          final entry = getEcranEtTitre(widget.typeCategorie, sousCat);
                          final screen = entry?.builder();
                          if (screen != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Aucun écran défini pour $sousCat")));
                          }
                        },
                      );
                    }).toList(),
              );
            }

            // ----------------------------------------------------
            // A retravailler - Ne fonctionne pas pour les biens immobiliers
            // ----------------------------------------------------

            if (!avecBien) {
              if (postes.isEmpty) {
                return CustomCard(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: const Center(child: Text("Ajouter une déclaration", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                );
              }

              final total = postes.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));

              postes.sort((a, b) => (b.emissionCalculee ?? 0).compareTo(a.emissionCalculee ?? 0));

              // ----------------------------------------------------
              // Affichage pour les cas sans bien immobilier
              // ----------------------------------------------------

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      final entry = getEcranEtTitre(widget.typeCategorie, widget.sousCategorie);
                      final screen = entry?.builder();

                      if (screen != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Aucun écran défini pour ${widget.sousCategorie}")));
                      }
                    },
                    child: CustomCard(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(widget.sousCategorie, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Row(
                                children: [
                                  Text("${total.round()} kgCO₂", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 14),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 8),
                          ...List.generate(postes.length * 2 - 1, (index) {
                            if (index.isEven) {
                              final poste = postes[index ~/ 2];
                              return PostListCard(title: poste.nomPoste ?? 'Sans nom', emission: "${poste.emissionCalculee?.round() ?? 0} kgCO₂", onEdit: () {}, onDelete: () {});
                            } else {
                              return const Divider(height: 1, thickness: 0.2, color: Colors.grey);
                            }
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              // ----------------------------------------------------
              // Affichage pour les cas impliquant un bien immobilier
              // ----------------------------------------------------
            } else {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: biensFuture,
                builder: (context, biensSnapshot) {
                  if (biensSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
                  }

                  if (biensSnapshot.hasError) {
                    return Padding(padding: const EdgeInsets.all(16), child: Text("Erreur : ${biensSnapshot.error}"));
                  }

                  final biens = biensSnapshot.data ?? [];
                  final widgets = <Widget>[];

                  for (var bien in biens) {
                    final idBien = bien['ID_Bien'];
                    final postesPourCeBien = postes.where((p) => p.idBien == idBien).toList();

                    if (postesPourCeBien.isNotEmpty) {
                      final total = postesPourCeBien.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));

                      widgets.add(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 3, left: 12),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(bien['Type_Bien'] ?? '', style: const TextStyle(fontSize: 12))]),
                            ),
                            CustomCard(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              child: InkWell(
                                onTap: () {
                                  final entry = getEcranEtTitre(widget.typeCategorie, widget.sousCategorie);
                                  final screen = entry?.builder();

                                  if (screen != null) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Aucun écran défini pour ${widget.sousCategorie}")));
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(widget.sousCategorie, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Row(
                                          children: [
                                            Text("${total.round()} kgCO₂", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.chevron_right, size: 14),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 8),
                                    ...List.generate(postesPourCeBien.length * 2 - 1, (index) {
                                      if (index.isEven) {
                                        final poste = postesPourCeBien[index ~/ 2];
                                        return PostListCard(title: poste.nomPoste ?? 'Sans nom', emission: "${poste.emissionCalculee?.round() ?? 0} kgCO₂", onEdit: () {}, onDelete: () {});
                                      } else {
                                        return const Divider(height: 1, thickness: 0.2, color: Colors.grey);
                                      }
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      widgets.add(
                        CustomCard(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: InkWell(
                            onTap: () => handleAdd(bien['ID_Bien']),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [Text("Ajouter une déclaration pour ${bien['Dénomination'] ?? ''}", style: const TextStyle(fontSize: 12)), const Icon(Icons.chevron_right, size: 14)],
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  return Column(children: widgets);
                },
              );
            }
          },
        ),
      ],
    );
  }
}
