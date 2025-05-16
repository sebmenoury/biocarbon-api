import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../data/services/api_service.dart';
import '../../data/models/poste.dart';
import '../../ui/widgets/biens_poste_card_group.dart';
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
                    ...List.generate(postes.length * 2 - 1, (index) {
                      if (index.isEven) {
                        final poste = postes[index ~/ 2];
                        return PostListCard(
                          title: poste.nomPoste ?? 'Sans nom',
                          emission:
                              "${poste.emissionCalculee?.toStringAsFixed(0) ?? '0'} kgCO₂",
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

                  // Si des biens existent
                  final biensAvecPostes = <Map<String, dynamic>>[];
                  final biensSansPostes = <Map<String, dynamic>>[];

                  for (var bien in biens) {
                    final idBien = bien['ID_Bien'];
                    final postesPourCeBien =
                        postes.where((p) => p.idBien == idBien).toList();
                    if (postesPourCeBien.isNotEmpty) {
                      bien['__postes'] = postesPourCeBien;
                      biensAvecPostes.add(bien);
                    } else {
                      biensSansPostes.add(bien);
                    }
                  }

                  final widgets = <Widget>[];

                  for (var bien in biensAvecPostes) {
                    widgets.add(
                      BienPosteCardGroup(
                        bien: bien,
                        postes:
                            (bien['__postes'] as List<Poste>)
                                .map(
                                  (p) => {
                                    'Nom_Usage': p.nomPoste ?? '',
                                    'Emission_Calculee':
                                        p.emissionCalculee ?? 0,
                                    'ID_Usage': p.idUsage ?? '',
                                  },
                                )
                                .toList(),
                        sousCategorie:
                            "${widget.sousCategorie} – ${bien['Dénomination'] ?? ''}",
                        onAdd: () => handleAdd(bien['ID_Bien']),
                        onEdit: (poste) => handleEdit(),
                        onDelete: (poste) => handleDelete(),
                        //typeBien: bien['Type_Bien'] ?? '',
                      ),
                    );
                  }

                  if (biensSansPostes.isNotEmpty) {
                    widgets.add(
                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ajouter des équipements à mes autres biens",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...biensSansPostes.map(
                              (bien) => ListTile(
                                title: Text(bien['Dénomination'] ?? ''),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () => handleAdd(bien['ID_Bien']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
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
