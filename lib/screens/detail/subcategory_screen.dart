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

  void handleEdit(Poste poste) {
    // TODO: Naviguer vers un écran de modification
  }

  void handleDelete(Poste poste) {
    // TODO: Ajouter une confirmation et supprimer
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

            // Regroupement par Type_Poste - Sous_Categorie
            final Map<String, List<Poste>> grouped = {};
            for (var poste in postes) {
              final key =
                  '${poste.typePoste ?? 'Inconnu'} - ${poste.sousCategorie ?? 'Autre'}';
              grouped.putIfAbsent(key, () => []).add(poste);
            }

            return Column(
              children:
                  grouped.entries.map<Widget>((entry) {
                    final groupTitle = entry.key;
                    final groupPostes = entry.value;

                    return CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...groupPostes.map<Widget>(
                            (poste) => PostListCard(
                              title: poste.nomPoste ?? poste.sousCategorie,
                              subtitle:
                                  "Quantité : ${poste.quantite} ${poste.unite}",
                              emission:
                                  "${poste.emissionCalculee.toStringAsFixed(2)} kgCO₂e",
                              onEdit: () => handleEdit(poste),
                              onDelete: () => handleDelete(poste),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }
}
