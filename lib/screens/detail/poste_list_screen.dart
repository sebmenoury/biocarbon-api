import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../ui/widgets/biens_poste_card_group.dart';
import '../../core/utils/sous_categorie_avec_bien.dart';
import '../../ui/layout/base_screen.dart';

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
  List<Map<String, dynamic>> postes = [];
  List<Map<String, dynamic>> biens = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final fetchedPostes = await ApiService.getUCPostes(
        widget.codeIndividu,
        widget.valeurTemps,
      );

      final fetchedBiens =
          sousCategoriesAvecBien.contains(widget.sousCategorie)
              ? await ApiService.getBiens(widget.codeIndividu)
              : [];

      if (!mounted) return;

      setState(() {
        postes = List<Map<String, dynamic>>.from(fetchedPostes);
        biens = List<Map<String, dynamic>>.from(fetchedBiens);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  void ajouterPostePourBien(String idBien) {
    // TODO: Naviguer vers le formulaire d'ajout avec idBien
  }

  void modifierPoste(Map<String, dynamic> poste) {
    // TODO: Naviguer vers l'écran d'édition
  }

  void supprimerPoste(Map<String, dynamic> poste) {
    // TODO: Appeler ApiService.deleteUCPoste(poste['ID_Usage']) puis recharger
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BaseScreen(
      title: Text(widget.sousCategorie),
      child: _buildPosteList(context),
    );
  }

  Widget _buildPosteList(BuildContext context) {
    final avecBien = sousCategoriesAvecBien.contains(widget.sousCategorie);

    if (avecBien) {
      if (biens.isEmpty) {
        return Center(
          child: TextButton.icon(
            onPressed: () {
              // TODO: Naviguer vers l'écran d'ajout de bien immobilier
            },
            icon: const Icon(Icons.add),
            label: const Text("Ajouter un bien immobilier"),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children:
            biens.map((bien) {
              final idBien = bien['ID_Bien'];
              final postesPourCeBien =
                  postes
                      .where(
                        (p) =>
                            p['ID_Bien'] == idBien &&
                            p['Sous_Catégorie'] == widget.sousCategorie,
                      )
                      .toList();

              return BienPosteCardGroup(
                bien: bien,
                postes: List<Map<String, dynamic>>.from(postesPourCeBien),
                sousCategorie: widget.sousCategorie,
                onAdd: () => ajouterPostePourBien(idBien),
                onEdit: modifierPoste,
                onDelete: supprimerPoste,
              );
            }).toList(),
      );
    } else {
      final postesFiltres =
          postes
              .where((p) => p['Sous_Catégorie'] == widget.sousCategorie)
              .toList();

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: postesFiltres.length,
        itemBuilder: (context, index) {
          final poste = postesFiltres[index];
          return Card(
            child: ListTile(
              title: Text(
                '${poste['Nom_Usage'] ?? "Mesure"} : ${poste['Emission_Calculee']} kgCO₂',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => modifierPoste(poste),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => supprimerPoste(poste),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
