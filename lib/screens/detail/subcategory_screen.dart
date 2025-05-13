import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../data/services/api_service.dart';
import '../../data/models/poste.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../ui/layout/custom_card.dart';

class SubCategorieScreen extends StatefulWidget {
  final String typeCategorie;
  final String codeIndividu;
  final String valeurTemps;

  const SubCategorieScreen({
    super.key,
    required this.typeCategorie,
    required this.codeIndividu,
    required this.valeurTemps,
  });

  @override
  State<SubCategorieScreen> createState() => _SubCategorieScreenState();
}

class _SubCategorieScreenState extends State<SubCategorieScreen> {
  late Future<List<Poste>> postesFuture;

  @override
  void initState() {
    super.initState();
    postesFuture = ApiService.getPostesByCategorie(
      widget.typeCategorie,
      widget.codeIndividu,
      widget.valeurTemps,
    );
  }

  void handleGroupEdit(String typePoste, String sousCategorie) {
    // TODO : Naviguer vers l'écran de saisie du groupe
  }

  void handleGroupAdd(String typePoste, String sousCategorie) {
    // TODO : Naviguer vers un ajout de poste dans ce groupe
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: widget.typeCategorie,
      children: [
        FutureBuilder<List<Poste>>(
          future: postesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erreur : ${snapshot.error}"));
            }

            final postes = snapshot.data!;
            if (postes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Aucun poste déclaré dans cette catégorie."),
              );
            }

            // Total global de la catégorie
            final totalEmission = postes.fold<double>(
              0,
              (sum, p) => sum + (p.emissionCalculee ?? 0),
            );

            // Regrouper par Type_Poste - Sous_Categorie avec somme par groupe
            final Map<String, List<Poste>> grouped = {};
            final Map<String, double> groupSums = {};

            for (var poste in postes) {
              final type = poste.typePoste ?? 'Inconnu';
              final sousCat = poste.sousCategorie ?? 'Autre';
              final key = '$type - $sousCat';

              grouped.putIfAbsent(key, () => []).add(poste);
              groupSums[key] =
                  (groupSums[key] ?? 0) + (poste.emissionCalculee ?? 0);
            }

            // Trier les groupes par émission décroissante
            final sortedKeys =
                groupSums.keys.toList()
                  ..sort((a, b) => groupSums[b]!.compareTo(groupSums[a]!));

            return Column(
              children: [
                // Carte récap globale Logement
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Logement",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(totalEmission / 1000).toStringAsFixed(2)} tCO₂e",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),

                // Cartes par groupe
                ...sortedKeys.map((key) {
                  final posts = grouped[key]!;
                  final sum = groupSums[key]!;
                  final pourcentage = (sum / totalEmission * 100)
                      .toStringAsFixed(1);
                  final type = posts.first.typePoste ?? 'Inconnu';
                  final sousCat = posts.first.sousCategorie ?? 'Autre';

                  return CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre avec actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "$type - $sousCat",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed:
                                      () => handleGroupEdit(type, sousCat),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed:
                                      () => handleGroupAdd(type, sousCat),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          "${sum.toStringAsFixed(2)} kgCO₂e • $pourcentage%",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        ...posts.map<Widget>(
                          (poste) => PostListCard(
                            title: poste.nomPoste ?? poste.sousCategorie,
                            subtitle:
                                "Quantité : ${poste.quantite} ${poste.unite}",
                            emission:
                                "${poste.emissionCalculee.toStringAsFixed(2)} kgCO₂e",
                            onEdit: () {},
                            onDelete: () {},
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}
