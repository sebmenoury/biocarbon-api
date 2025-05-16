import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
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
  List<dynamic> postes = [];
  List<dynamic> biens = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final fetchedPostes = await ApiService.getUCPostes(widget.codeIndividu);
      final fetchedBiens =
          sousCategoriesAvecBien.contains(widget.sousCategorie)
              ? await ApiService.getBiens(widget.codeIndividu)
              : [];

      if (!mounted) return;

      setState(() {
        postes = fetchedPostes;
        biens = fetchedBiens;
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
    // TODO: Naviguer vers le formulaire d'ajout avec idBien, widget.codeIndividu, widget.valeurTemps
  }

  void modifierPoste(Map<String, dynamic> poste) {
    // TODO: Naviguer vers l'écran d'édition
  }

  void supprimerPoste(Map<String, dynamic> poste) {
    // TODO: Appeler ApiService.deleteUCPoste(poste['ID_Usage']) puis recharger
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sousCategorie)),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPosteList(context),
    );
  }

  Widget _buildPosteList(BuildContext context) {
    final avecBien = sousCategoriesAvecBien.contains(widget.sousCategorie);

    if (avecBien) {
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
                      .toList()
                      .cast<Map<String, dynamic>>();

              return BienPosteCardGroup(
                bien: bien,
                postes: postesPourCeBien,
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
              .toList()
              .cast<Map<String, dynamic>>();

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
