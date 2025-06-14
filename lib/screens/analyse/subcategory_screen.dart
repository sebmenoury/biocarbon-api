import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/app_icons.dart';
import '../../data/classes/poste_postes.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../ui/layout/custom_card.dart';

class SubCategorieScreen extends StatefulWidget {
  final String typeCategorie;
  final String codeIndividu;
  final String valeurTemps;

  const SubCategorieScreen({super.key, required this.typeCategorie, required this.codeIndividu, required this.valeurTemps});

  @override
  State<SubCategorieScreen> createState() => _SubCategorieScreenState();
}

class _SubCategorieScreenState extends State<SubCategorieScreen> {
  late Future<List<Poste>> postesFuture;

  @override
  void initState() {
    super.initState();
    postesFuture = ApiService.getPostesByCategorie(widget.typeCategorie, widget.codeIndividu, widget.valeurTemps);
  }

  void handleGroupEdit(String typePoste, String sousCategorie) {}
  void handleGroupAdd(String typePoste, String sousCategorie) {}

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          Text(widget.typeCategorie, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
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
              return const Padding(padding: EdgeInsets.all(8), child: Text("Aucun poste déclaré dans cette catégorie."));
            }

            final totalEmission = postes.fold<double>(0, (sum, p) => sum + (p.emissionCalculee ?? 0));

            final Map<String, List<Poste>> grouped = {};
            final Map<String, double> groupSums = {};

            for (var poste in postes) {
              final type = poste.typePoste ?? 'Inconnu';
              final sousCat = poste.sousCategorie ?? 'Autre';
              final key = '$type - $sousCat';
              grouped.putIfAbsent(key, () => []).add(poste);
              groupSums[key] = (groupSums[key] ?? 0) + (poste.emissionCalculee ?? 0);
            }

            final sortedKeys = groupSums.keys.toList()..sort((a, b) => groupSums[b]!.compareTo(groupSums[a]!));

            return Column(
              children: [
                // Carte récap globale Logement
                CustomCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(categoryIcons[widget.typeCategorie] ?? Icons.label_outline, size: 16, color: categoryColors[widget.typeCategorie] ?? Colors.grey[700]),
                      const SizedBox(width: 12),
                      Expanded(child: Text(widget.typeCategorie, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      Text("${(totalEmission / 1000).toStringAsFixed(2)} tCO₂", style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),

                // Cartes par groupe
                ...sortedKeys.map((key) {
                  final posts = grouped[key]!;
                  final sum = groupSums[key]!;
                  final pourcentage = (sum / totalEmission * 100).toStringAsFixed(1);
                  final type = posts.first.typePoste ?? 'Inconnu';
                  final sousCat = posts.first.sousCategorie ?? 'Autre';

                  // ✅ Trie ici les postes par émission décroissante
                  posts.sort((a, b) => (b.emissionCalculee ?? 0).compareTo(a.emissionCalculee ?? 0));

                  return CustomCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      children: [
                        // Ligne combinée type titre/sous-titre + trailing + actions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bloc gauche : titre + sous-titre
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sousCat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text("$pourcentage% ($type)", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),

                            // Bloc trailing : valeur émission + actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("${sum.round()} kgCO", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right, size: 14),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 8),

                        // Liste des postes
                        ...List.generate(posts.length * 2 - 1, (index) {
                          if (index.isEven) {
                            final poste = posts[index ~/ 2];
                            return PostListCard(
                              title: poste.nomPoste ?? poste.sousCategorie,
                              emission: "${poste.emissionCalculee?.round()} kgCO₂",
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
