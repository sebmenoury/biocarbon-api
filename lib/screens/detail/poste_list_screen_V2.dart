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

  const PosteListScreen({super.key, required this.sousCategorie, required this.codeIndividu, required this.valeurTemps});

  @override
  State<PosteListScreen> createState() => _PosteListScreenState();
}

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

  void handleAdd(String? idBien) {
    if (idBien == null) return;
    Navigator.pushNamed(
      context,
      '/construction_screen',
      arguments: {'idBien': idBien, 'codeIndividu': widget.codeIndividu, 'valeurTemps': widget.valeurTemps, 'sousCategorie': widget.sousCategorie},
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
          Text(widget.sousCategorie, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

            if (widget.sousCategorie == 'Alimentation') {
              final Map<String, List<Poste>> postesParSousCat = {};
              for (var poste in postes) {
                final key = poste.sousCategorie;
                if (!postesParSousCat.containsKey(key)) {
                  postesParSousCat[key] = [];
                }
                postesParSousCat[key]!.add(poste);
              }

              return Column(
                children:
                    postesParSousCat.entries.map((entry) {
                      final sousCat = entry.key;
                      final postes = entry.value;
                      final total = postes.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));

                      postes.sort((a, b) => (b.emissionCalculee ?? 0).compareTo(a.emissionCalculee ?? 0));

                      return CustomCard(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(sousCat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                  onEdit: () {},
                                  onDelete: () {},
                                );
                              } else {
                                return const Divider(height: 1, thickness: 0.2, color: Colors.grey);
                              }
                            }),
                          ],
                        ),
                      );
                    }).toList(),
              );
            }

            if (!avecBien) {
              if (postes.isEmpty) {
                return CustomCard(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/construction_screen'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Déclarer mes premiers éléments concernant ce thème", style: TextStyle(fontSize: 12)),
                        const Icon(Icons.chevron_right, size: 14),
                      ],
                    ),
                  ),
                );
              }

              final total = postes.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));

              postes.sort((a, b) => (b.emissionCalculee ?? 0).compareTo(a.emissionCalculee ?? 0));

              return Column(
                children: [
                  InkWell(
                    onTap: handleEdit,
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
                              return PostListCard(
                                title: poste.nomPoste ?? 'Sans nom',
                                emission: "${poste.emissionCalculee?.round() ?? 0} kgCO₂",
                                onEdit: () {},
                                onDelete: () {},
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

                  if (biens.isEmpty) {
                    return CustomCard(
                      padding: const EdgeInsets.all(12),
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/construction_screen'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Veuillez commencer par déclarer un bien immobilier", style: TextStyle(fontSize: 12)),
                            const Icon(Icons.chevron_right, size: 14),
                          ],
                        ),
                      ),
                    );
                  }

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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [Text(bien['Type_Bien'] ?? '', style: const TextStyle(fontSize: 12))],
                              ),
                            ),
                            CustomCard(
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
                                  ...List.generate(postesPourCeBien.length * 2 - 1, (index) {
                                    if (index.isEven) {
                                      final poste = postesPourCeBien[index ~/ 2];
                                      return PostListCard(
                                        title: poste.nomPoste ?? 'Sans nom',
                                        emission: "${poste.emissionCalculee?.round() ?? 0} kgCO₂",
                                        onEdit: () {},
                                        onDelete: () {},
                                      );
                                    } else {
                                      return const Divider(height: 1, thickness: 0.2, color: Colors.grey);
                                    }
                                  }),
                                ],
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
                              children: [
                                Text("Ajouter une déclaration pour ${bien['Dénomination'] ?? ''}", style: const TextStyle(fontSize: 12)),
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
