import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../data/services/api_service.dart';
import '../../data/models/poste.dart';
import '../../ui/widgets/post_group_card.dart';
import '../../core/utils/sous_categorie_avec_bien.dart';

class PosteListScreen extends StatefulWidget {
  final String sousCategorie;
  final String codeIndividu;
  final String valeurTemps;

  const PosteListScreen({
    super.key,
    required this.sousCategorie,
    required this.codeIndividu,
    required this.valeurTemps,
  });

  @override
  State<PosteListScreen> createState() => _PosteListScreenState();
}

class _PosteListScreenState extends State<PosteListScreen> {
  late Future<List<Poste>> postesFuture;
  late Future<List<Map<String, dynamic>>> biensFuture;
  bool avecBien = false;

  @override
  void initState() {
    super.initState();
    avecBien = sousCategoriesAvecBien.contains(widget.sousCategorie);
    postesFuture = ApiService.getPostesBysousCategorie(
      widget.sousCategorie,
      widget.codeIndividu,
      widget.valeurTemps,
    );
    if (avecBien) {
      biensFuture = ApiService.getBiens(
        widget.codeIndividu,
      ).then((biens) => biens.cast<Map<String, dynamic>>());
    }
  }

  void handleAdd([String? idBien]) {
    debugPrint(
      "Ajout d’un poste pour ${widget.sousCategorie} lié au bien $idBien",
    );
  }

  void handleEdit() {
    debugPrint("Modifier ${widget.sousCategorie}");
  }

  void handleDelete() {
    debugPrint("Suppression de ${widget.sousCategorie}");
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            widget.sousCategorie,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 13),
                tooltip: 'Modifier',
                onPressed: handleEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 13),
                tooltip: 'Supprimer',
                onPressed: handleDelete,
              ),
            ],
          ),
        ),
        FutureBuilder<List<Poste>>(
          future: postesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Erreur : ${snapshot.error}"),
              );
            }

            final postes = snapshot.data ?? [];

            if (!avecBien) {
              if (postes.isEmpty) {
                return CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "Vous n'avez pas encore de déclaration sur ce poste, veuillez commencer à déclarer des éléments concernant le thème : ${widget.sousCategorie}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }

              final total = postes.fold<double>(
                0,
                (sum, p) => sum + (p.emissionCalculee ?? 0),
              );

              final postDataList =
                  postes
                      .map(
                        (p) => PostData(
                          title: p.nomPoste ?? 'Sans nom',
                          emission: p.emissionCalculee ?? 0,
                          onEdit: () {},
                          onDelete: () {},
                        ),
                      )
                      .toList();

              return PostGroupCard(
                sousCategorie: widget.sousCategorie,
                posts: postDataList,
                totalCategorieEmission: total,
              );
            } else {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: biensFuture,
                builder: (context, biensSnapshot) {
                  if (biensSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (biensSnapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("Erreur : ${biensSnapshot.error}"),
                    );
                  }

                  final biens = biensSnapshot.data ?? [];

                  if (biens.isEmpty) {
                    return CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text(
                              "Veuillez commencer par déclarer un bien immobilier",
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text("Retour à Mes données"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final widgets = <Widget>[];

                  for (var bien in biens) {
                    final idBien = bien['ID_Bien'];
                    final postesPourCeBien =
                        postes.where((p) => p.idBien == idBien).toList();

                    if (postesPourCeBien.isNotEmpty) {
                      final postDataList =
                          postesPourCeBien
                              .map(
                                (p) => PostData(
                                  title: p.nomPoste ?? 'Sans nom',
                                  emission: p.emissionCalculee ?? 0,
                                  onEdit: () {},
                                  onDelete: () {},
                                ),
                              )
                              .toList();

                      widgets.add(
                        PostGroupCard(
                          sousCategorie:
                              "${widget.sousCategorie} – ${bien['Dénomination'] ?? ''}",
                          posts: postDataList,
                          totalCategorieEmission: postDataList.fold(
                            0,
                            (sum, p) => sum + p.emission,
                          ),
                        ),
                      );
                    } else {
                      widgets.add(
                        ListTile(
                          title: Text(
                            "Ajouter une déclaration pour ${bien['Dénomination'] ?? ''}",
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => handleAdd(bien['ID_Bien']),
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
