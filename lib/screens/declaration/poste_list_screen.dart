import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../core/constants/app_icons.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../ui/widgets/post_list_section_card.dart';
import '../../data/services/api_service.dart';
import '../../data/classes/poste_postes.dart';
import 'sous_categorie_avec_bien.dart';

import 'eqt_bien_immobilier/construction_screen.dart';
import 'eqt_vehicules/vehicule_screen.dart';
import '../../core/constants/app_titre_categorie.dart';
import '../main/mes_donnees_screen.dart';
import 'navigation_registry.dart';
import 'eqt_equipements/equipement_screen.dart';
import 'eqt_confort/equipement_confort_screen.dart';
import 'bien_renovation/renovation_screen.dart';
import 'usage_logement/usages_electricite_screen.dart';
import 'usage_logement/usages_gaz_fioul_screen.dart';
import 'usage_logement/usages_dechets_eau_screen.dart';
import 'usage_alimentation/alimentation_screen.dart';

const List<String> usageLabels = [
  'Electricité',
  'Gaz et Fioul',
  'Déchets et Eau',
  'Alimentation',
  'Loisirs',
  'Habillement',
  'Banques et Assurances',
  'Déplacements Avion',
  'Déplacements Voiture',
  'Déplacements Train/Métro/Bus',
  'Déplacements Autres',
  'Services publics',
];

class PosteListScreen extends StatefulWidget {
  final String typeCategorie;
  final String sousCategorie;
  final String codeIndividu;
  final String valeurTemps;
  final String? idBien;
  final VoidCallback? onAddPressed;

  const PosteListScreen({super.key, required this.typeCategorie, required this.sousCategorie, required this.codeIndividu, required this.valeurTemps, this.idBien, this.onAddPressed});

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

    // 🔁 Gestion cas particuliers
    if (widget.typeCategorie == "Alimentation" || widget.typeCategorie == "Services publics") {
      // ✅ On filtre par typeCategorie
      postesFuture = ApiService.getUCPostesFiltres(typeCategorie: widget.typeCategorie, codeIndividu: widget.codeIndividu, annee: widget.valeurTemps);
    } else {
      // 🧩 Cas normal : filtrage par sous-catégorie
      postesFuture = ApiService.getUCPostesFiltres(sousCategorie: widget.sousCategorie, codeIndividu: widget.codeIndividu, annee: widget.valeurTemps);
    }

    if (avecBien) {
      biensFuture = ApiService.getBiens(widget.codeIndividu).then((biens) => biens.cast<Map<String, dynamic>>());
    }
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
            if (widget.codeIndividu != null && widget.idBien != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => VehiculeScreen(
                        codeIndividu: widget.codeIndividu!,
                        idBien: widget.idBien!,
                        onSave: () {
                          setState(() {
                            postesFuture = ApiService.getUCPostesFiltres(sousCategorie: widget.sousCategorie, codeIndividu: widget.codeIndividu, annee: widget.valeurTemps);
                          });
                        },
                      ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner un des logements pour y attribuer vos véhicules.")));
            }
          }
        });
      });
    }
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
          Center(child: Text(titreParSousCategorie[widget.sousCategorie] ?? widget.sousCategorie!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              iconSize: 18,
              onPressed: () {
                final isUsage = usageLabels.contains(widget.sousCategorie);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MesDonneesScreen(initialTabIndex: isUsage ? 1 : 0)));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
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
            // Cas particulier pour l'alimentation
            // ----------------------------------------------------

            if (widget.typeCategorie == "Alimentation") {
              final Map<String, List<Poste>> postesParSousCat = {};
              for (var poste in postes) {
                final key = poste.sousCategorie;
                if (!postesParSousCat.containsKey(key)) {
                  postesParSousCat[key] = [];
                }
                postesParSousCat[key]!.add(poste);
              }

              final hasData = postesParSousCat.isNotEmpty;

              final List<MapEntry<String, List<Poste>>> sortedEntries = postesParSousCat.entries.toList();

              // Ajoute les totaux et trie par total décroissant
              try {
                sortedEntries.sort((a, b) {
                  final totalA = a.value.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));
                  final totalB = b.value.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));
                  return totalB.compareTo(totalA);
                });
                print("✅ Tri effectué avec succès");
              } catch (e) {
                print("❌ Erreur pendant le tri : $e");
              }

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      "⚙️ Indiquez vos habitudes d'alimentation. Elles sont traduites en empreinte carbone après une transformation en poids par aliment consommé. \n",
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!hasData)
                    CustomCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text("Déclarer votre alimentation", style: const TextStyle(fontSize: 12)), const Icon(Icons.chevron_right, size: 14)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AlimentationScreen(codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps, onSave: () => setState(() {}))),
                        );
                      },
                    ),

                  ...sortedEntries.map((entry) {
                    try {
                      final sousCat = entry.key;
                      final postes = entry.value;
                      final total = postes.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));

                      postes.sort((a, b) => (b.emissionCalculee ?? 0).compareTo(a.emissionCalculee ?? 0));

                      return PostListSectionCard(
                        sousCat: sousCat,
                        postes: postes,
                        total: total,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AlimentationScreen(codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps, onSave: () => setState(() {}))),
                          );
                        },
                      );
                    } catch (e) {
                      print("❌ Erreur dans la génération d'une card alimentation : $e");
                      return const SizedBox(); // Affiche rien si erreur
                    }
                  }).toList(),
                ],
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
                      final entry = getEcranEtTitre(widget.typeCategorie, widget.sousCategorie!);
                      final screen = entry?.builder();

                      if (screen != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
                      } else {
                        print('🚗 Ici');
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
                              Text(widget.sousCategorie!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                              return PostListCard(
                                title: poste.nomPoste ?? 'Sans nom',
                                emission: "${poste.emissionCalculee?.round() ?? 0} kgCO₂",
                                onTap: () {
                                  print("🚗 Tap sur ${poste.nomPoste}");
                                  // Navigation ou popup à implémenter
                                },
                                onEdit: () {
                                  // ouvrir formulaire de modif
                                },
                                onDelete: () {
                                  // action suppression
                                },
                              );
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

                  // ----------------------------------------------------
                  // texte pour la liste construction immobilière
                  // ----------------------------------------------------

                  if (widget.sousCategorie == 'Construction') {
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "⚙️ On retrouve ici l'amortissement de l'énergie grise associée à la construction des éléments structurels du logement.",
                              style: TextStyle(fontSize: 11),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 6),
                            const Text("L'amortissement de ces émissions est calculé de la façon suivante :", style: TextStyle(fontSize: 11)),
                            const SizedBox(height: 4),
                            const Center(
                              child: Text(
                                "Émissions énergie grise construction (/m²)\n"
                                "× Surface du bien (en m²)\n"
                                "× Facteur de pondération (période de construction)\n"
                                "/ Nombre de propriétaires",
                                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40), // 👈 padding ajusté
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
                          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(imageParSousCategorie[widget.sousCategorie]!, fit: BoxFit.contain)),
                        ),
                      ),
                    );

                    // 👇 Espace sous l'image
                    widgets.add(const SizedBox(height: 18));
                  }
                  // ----------------------------------------------------
                  // 🔁 Tous les autres cas gérés via la map texteParSousCategorie
                  // ----------------------------------------------------
                  else if (texteParSousCategorie.containsKey(widget.sousCategorie)) {
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(texteParSousCategorie[widget.sousCategorie]!, style: const TextStyle(fontSize: 11, height: 1.4), textAlign: TextAlign.justify)),
                            if (infoBulleParSousCategorie.containsKey(widget.sousCategorie))
                              Tooltip(
                                message: infoBulleParSousCategorie[widget.sousCategorie]!,
                                padding: const EdgeInsets.all(12),
                                textStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.info_outline, size: 16, color: Colors.grey)),
                              ),
                          ],
                        ),
                      ),
                    );

                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: imageParSousCategorie.containsKey(widget.sousCategorie) ? Image.asset(imageParSousCategorie[widget.sousCategorie]!, fit: BoxFit.contain) : const SizedBox.shrink(),
                      ),
                    );

                    widgets.add(const SizedBox(height: 12));
                  }

                  // ----------------------------------------------------
                  // suite du code pour afficher les biens immobiliers
                  // ----------------------------------------------------
                  for (var bien in biens) {
                    final idBien = bien['ID_Bien'];
                    final postesPourCeBien = postes.where((p) => p.idBien == idBien).toList();
                    postesPourCeBien.sort((a, b) => (b.emissionCalculee ?? 0).compareTo(a.emissionCalculee ?? 0));

                    if (postesPourCeBien.isNotEmpty) {
                      final total = postesPourCeBien.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));

                      // Bien existant reconstitué depuis les données disponibles

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
                                  final idBien = bien['ID_Bien'];

                                  if (widget.sousCategorie == "Construction") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ConstructionScreen(
                                              codeIndividu: widget.codeIndividu,
                                              valeurTemps: widget.valeurTemps,
                                              sousCategorie: widget.sousCategorie!,
                                              idBien: idBien,
                                              onSave: () => setState(() {}),
                                            ),
                                      ),
                                    );
                                  } else if (widget.sousCategorie == "Véhicules") {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => VehiculeScreen(codeIndividu: widget.codeIndividu, idBien: idBien, onSave: () => setState(() {}))));
                                  } else if (["Equipements Bricolage", "Equipements Ménager", "Equipements Multi-media"].contains(widget.sousCategorie)) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EquipementScreen(codeIndividu: widget.codeIndividu, idBien: idBien, sousCategorie: widget.sousCategorie!, onSave: () => setState(() {})),
                                      ),
                                    );
                                  } else if (widget.sousCategorie == "Equipements Confort") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EquipementConfortScreen(codeIndividu: widget.codeIndividu, idBien: idBien, sousCategorie: widget.sousCategorie!, onSave: () => setState(() {})),
                                      ),
                                    );
                                  } else if (widget.sousCategorie == "Rénovation") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RenovationScreen(codeIndividu: widget.codeIndividu, idBien: idBien, valeurTemps: widget.valeurTemps, onSave: () => setState(() {})),
                                      ),
                                    );
                                  } else if (widget.sousCategorie == "Electricité") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => UsagesElectriciteScreen(
                                              codeIndividu: widget.codeIndividu,
                                              idBien: idBien,
                                              sousCategorie: widget.sousCategorie!,
                                              valeurTemps: widget.valeurTemps,
                                              onSave: () => setState(() {}),
                                            ),
                                      ),
                                    );
                                  } else if (widget.sousCategorie == "Gaz et Fioul") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => UsagesGazFioulScreen(
                                              codeIndividu: widget.codeIndividu,
                                              idBien: idBien,
                                              sousCategorie: widget.sousCategorie!,
                                              valeurTemps: widget.valeurTemps,
                                              onSave: () => setState(() {}),
                                            ),
                                      ),
                                    );
                                  } else if (widget.sousCategorie == "Déchets et Eau") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => UsagesDechetsEauScreen(
                                              codeIndividu: widget.codeIndividu,
                                              idBien: idBien,
                                              sousCategorie: widget.sousCategorie!,
                                              valeurTemps: widget.valeurTemps,
                                              onSave: () => setState(() {}),
                                            ),
                                      ),
                                    );
                                  } else {
                                    final entry = getEcranEtTitre(widget.typeCategorie, widget.sousCategorie!);
                                    if (entry != null && entry.builder != null) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => entry.builder!()));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Écran non disponible pour cette sous-catégorie.")));
                                    }
                                  }
                                }, // 👈 FERMETURE ici du onTap

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(widget.sousCategorie!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                        return PostListCard(
                                          title: poste.nomPoste ?? 'Sans nom',
                                          emission: "${poste.emissionCalculee?.round() ?? 0} kgCO₂",
                                          onTap: () {
                                            print("🚗 Tap sur ${poste.nomPoste}");
                                            // Navigation ou popup à implémenter
                                          },
                                          onEdit: () {
                                            // ouvrir formulaire de modif
                                          },
                                          onDelete: () {
                                            // action suppression
                                          },
                                        );
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
                      // 🆕 Ajout d’une déclaration à partir de zéro
                      widgets.add(
                        CustomCard(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: InkWell(
                            onTap: () {
                              final idBien = bien['ID_Bien'];

                              if (widget.sousCategorie == "Construction") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ConstructionScreen(
                                          codeIndividu: widget.codeIndividu,
                                          valeurTemps: widget.valeurTemps,
                                          sousCategorie: widget.sousCategorie!,
                                          idBien: idBien,
                                          onSave: () => setState(() {}),
                                        ),
                                  ),
                                );
                              } else if (widget.sousCategorie == "Véhicules") {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => VehiculeScreen(codeIndividu: widget.codeIndividu, idBien: idBien, onSave: () => setState(() {}))));
                              } else if (["Equipements Bricolage", "Equipements Ménager", "Equipements Multi-media"].contains(widget.sousCategorie)) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EquipementScreen(codeIndividu: widget.codeIndividu, idBien: idBien, sousCategorie: widget.sousCategorie!, onSave: () => setState(() {})),
                                  ),
                                );
                              } else if (widget.sousCategorie == "Equipements Confort") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EquipementConfortScreen(codeIndividu: widget.codeIndividu, idBien: idBien, sousCategorie: widget.sousCategorie!, onSave: () => setState(() {})),
                                  ),
                                );
                              } else if (widget.sousCategorie == "Rénovation") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RenovationScreen(codeIndividu: widget.codeIndividu, idBien: idBien, valeurTemps: widget.valeurTemps, onSave: () => setState(() {})),
                                  ),
                                );
                              } else if (widget.sousCategorie == "Electricité") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UsagesElectriciteScreen(
                                          codeIndividu: widget.codeIndividu,
                                          idBien: idBien,
                                          sousCategorie: widget.sousCategorie!,
                                          valeurTemps: widget.valeurTemps,
                                          onSave: () => setState(() {}),
                                        ),
                                  ),
                                );
                              } else if (widget.sousCategorie == "Gaz et Fioul") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UsagesGazFioulScreen(
                                          codeIndividu: widget.codeIndividu,
                                          idBien: idBien,
                                          sousCategorie: widget.sousCategorie!,
                                          valeurTemps: widget.valeurTemps,
                                          onSave: () => setState(() {}),
                                        ),
                                  ),
                                );
                              } else if (widget.sousCategorie == "Déchets et Eau") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UsagesDechetsEauScreen(
                                          codeIndividu: widget.codeIndividu,
                                          idBien: idBien,
                                          sousCategorie: widget.sousCategorie!,
                                          valeurTemps: widget.valeurTemps,
                                          onSave: () => setState(() {}),
                                        ),
                                  ),
                                );
                              } else {
                                final entry = getEcranEtTitre(widget.typeCategorie, widget.sousCategorie!);
                                final screen = entry?.builder();

                                if (screen != null) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
                                } else {
                                  print('🚗 encore Là');
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Aucun écran défini pour ${widget.sousCategorie}")));
                                }
                              }
                            },
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
