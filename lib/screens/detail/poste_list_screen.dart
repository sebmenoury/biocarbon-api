import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../data/services/api_service.dart';
import '../../data/models/poste.dart';
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
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 1),
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
                return CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Déclarer mes premiers éléments concernant ce thème",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Icon(Icons.chevron_right, size: 12),
                      ],
                    ),
                  ),
                );
              }

              final total = postes.fold<double>(
                0,
                (sum, p) => sum + (p.emissionCalculee ?? 0),
              );

              postes.sort(
                (a, b) => (b.emissionCalculee ?? 0).compareTo(
                  a.emissionCalculee ?? 0,
                ),
              );

              return CustomCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.sousCategorie,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Total : ${total.round()} kgCO₂",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Divider(thickness: 0.5, height: 16),
                    ...postes.map(
                      (poste) => PostListCard(
                        title: poste.nomPoste ?? 'Sans nom',
                        emission:
                            "${poste.emissionCalculee?.toStringAsFixed(0) ?? '0'} kgCO₂",
                        onEdit: () {},
                        onDelete: () {},
                      ),
                    ),
                  ],
                ),
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
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Text(
                              "Veuillez commencer par déclarer un bien immobilier",
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            const Icon(Icons.chevron_right, size: 12),
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
                      final total = postesPourCeBien.fold<double>(
                        0,
                        (sum, p) => sum + (p.emissionCalculee ?? 0),
                      );

                      widgets.add(
                        CustomCard(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.sousCategorie,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "Total : ${total.round()} kgCO₂",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 8),
                              ...postesPourCeBien.map(
                                (poste) => PostListCard(
                                  title: poste.nomPoste ?? 'Sans nom',
                                  emission:
                                      "${poste.emissionCalculee?.toStringAsFixed(0) ?? '0'} kgCO₂",
                                  onEdit: () {},
                                  onDelete: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      widgets.add(
                        CustomCard(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          child: InkWell(
                            onTap: () => handleAdd(bien['ID_Bien']),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Ajouter une déclaration pour ${bien['Dénomination'] ?? ''}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Icon(Icons.chevron_right, size: 14),
                              ],
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
