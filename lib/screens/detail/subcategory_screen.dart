import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/app_icons.dart';
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

  void handleGroupEdit(String typePoste, String sousCategorie) {}
  void handleGroupAdd(String typePoste, String sousCategorie) {}

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

            final totalEmission = postes.fold<double>(
              0,
              (sum, p) => sum + (p.emissionCalculee ?? 0),
            );

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

            final sortedKeys =
                groupSums.keys.toList()
                  ..sort((a, b) => groupSums[b]!.compareTo(groupSums[a]!));

            return Column(
              children: [
                // Carte récap globale Logement
                CustomCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8, // ✅ corrigé ici
                  ),
                  child: Row(
                    children: [
                      Icon(
                        categoryIcons[widget.typeCategorie] ??
                            Icons.label_outline,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Logement",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "${(totalEmission / 1000).toStringAsFixed(2)} tCO₂e",
                        style: const TextStyle(fontSize: 11),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ligne 1 — Titre, valeur, icônes
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "$type - $sousCat",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              "${sum.round()} kgCO₂e",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 14),
                              onPressed: () => handleGroupEdit(type, sousCat),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 14),
                              onPressed: () => handleGroupAdd(type, sousCat),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 14),
                              onPressed: () {
                                // TODO: handleGroupDelete
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),

                        // Ligne 2 — Sous-titre
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0, bottom: 6.0),
                          child: Text(
                            "$type ($pourcentage%)",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        // Liste des postes
                        ...List.generate(posts.length * 2 - 1, (index) {
                          if (index.isEven) {
                            final poste = posts[index ~/ 2];
                            return PostListCard(
                              title: poste.nomPoste ?? poste.sousCategorie,
                              subtitle:
                                  "Quantité : ${poste.quantite} ${poste.unite}",
                              emission:
                                  "${poste.emissionCalculee?.round()} kgCO₂e",
                              onEdit: () {},
                              onDelete: () {},
                            );
                          } else {
                            return const Divider(
                              height: 1,
                              thickness: 0.2,
                              color: Colors.grey,
                            );
                          }
                        }),
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
