import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../../../data/classes/post_helper.dart';
import '../poste_list_screen.dart';
import 'poste_equipement.dart';

class EquipementScreen extends StatefulWidget {
  final String codeIndividu;
  final String idBien;
  final VoidCallback onSave;
  final String sousCategorie;

  const EquipementScreen({super.key, required this.codeIndividu, required this.idBien, required this.sousCategorie, required this.onSave});

  @override
  State<EquipementScreen> createState() => _EquipementScreenState();
}

class _EquipementScreenState extends State<EquipementScreen> {
  List<PosteEquipement> equipements = [];
  bool isLoading = true;
  double totalEmission = 0;
  bool hasPostesExistants = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final bien = await ApiService.getBienParId(widget.codeIndividu, widget.idBien);
    final denomination = bien['Dénomination'] ?? '';
    final typeBien = bien['Type_Bien'] ?? '';
    final nbProprietaires = int.tryParse(bien['Nb_Proprietaires']?.toString() ?? '1') ?? 1;

    final ref = await ApiService.getRefEquipements();
    final refFiltree = ref.where((e) => e['Type_Categorie'] == 'Biens' && ['Maison Ménager', 'Maison Bricolage', 'Electronique, telecoms'].contains(e['Sous_Categorie'])).toList();

    final postes = await ApiService.getUCPostesFiltres(idBien: widget.idBien);
    final existants = postes.where((p) => p.typeCategorie == "Biens").toList();
    hasPostesExistants = existants.isNotEmpty;

    final nomsExistants = existants.map((e) => e.nomPoste).toSet();

    List<PosteEquipement> resultat = [];

    // Nouveaux équipements
    for (final e in refFiltree) {
      if (nomsExistants.contains(e['Nom_Equipement'])) continue;
      resultat.add(
        PosteEquipement(
          nomEquipement: e['Nom_Equipement'],
          anneeAchat: DateTime.now().year,
          quantite: 0,
          facteurEmission: double.tryParse(e['Valeur_Emission_Grise'].toString()) ?? 0,
          dureeAmortissement: int.tryParse(e['Duree_Amortissement'].toString()) ?? 1,
          idBien: widget.idBien,
          typeBien: typeBien,
          nomLogement: denomination,
          nbProprietaires: nbProprietaires,
        ),
      );
    }

    // Déjà enregistrés
    for (final p in existants) {
      final refMatch = ref.firstWhere((e) => e['Nom_Equipement'] == p.nomPoste, orElse: () => {});
      resultat.add(
        PosteEquipement(
          nomEquipement: p.nomPoste!,
          quantite: p.quantite != null ? p.quantite!.round() : 1,
          anneeAchat: p.anneeAchat ?? DateTime.now().year,
          facteurEmission: double.tryParse(refMatch['Valeur_Emission_Grise'].toString()) ?? 0,
          dureeAmortissement: int.tryParse(refMatch['Duree_Amortissement'].toString()) ?? 1,
          idBien: widget.idBien,
          typeBien: typeBien,
          nomLogement: denomination,
          nbProprietaires: nbProprietaires,
          idUsageInitial: p.idUsage,
        ),
      );
    }

    setState(() {
      equipements = resultat;
      recalculerTotal();
      isLoading = false;
    });
  }

  double calculerEmission(PosteEquipement p) {
    final e = (p.quantite * p.facteurEmission) / p.dureeAmortissement;
    return e.isNaN ? 0 : e;
  }

  void recalculerTotal() {
    totalEmission = equipements.fold(0.0, (s, p) => s + calculerEmission(p));
  }

  Future<void> enregistrer() async {
    final codeIndividu = widget.codeIndividu;
    final valeurTemps = "2025";
    const sousCategorie = "Maison Ménager";

    await ApiService.deleteAllPostes(codeIndividu: codeIndividu, idBien: widget.idBien, valeurTemps: valeurTemps, sousCategorie: sousCategorie);

    for (int i = 0; i < equipements.length; i++) {
      final e = equipements[i];
      if (e.quantite > 0) {
        await ApiService.savePoste({
          "ID_Usage": "EQ-${DateTime.now().millisecondsSinceEpoch}_$i",
          "Code_Individu": codeIndividu,
          "Type_Temps": "Réel",
          "Valeur_Temps": valeurTemps,
          "Date_enregistrement": DateTime.now().toIso8601String(),
          "ID_Bien": e.idBien,
          "Type_Bien": e.typeBien,
          "Type_Poste": "Equipement",
          "Type_Categorie": "Biens",
          "Sous_Categorie": sousCategorie,
          "Nom_Poste": e.nomEquipement,
          "Nom_Logement": e.nomLogement,
          "Quantite": e.quantite,
          "Unite": "unité",
          "Facteur_Emission": e.facteurEmission,
          "Emission_Calculee": calculerEmission(e),
          "Mode_Calcul": "Amorti",
          "Annee_Achat": e.anneeAchat,
          "Duree_Amortissement": e.dureeAmortissement,
        });
      }
    }

    widget.onSave();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Équipements enregistrés")));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Biens", sousCategorie: sousCategorie, codeIndividu: codeIndividu, valeurTemps: valeurTemps)));
  }

  Future<void> supprimer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Supprimer ?"),
            content: const Text("Supprimer tous les équipements ?"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer"))],
          ),
    );

    if (confirm == true) {
      final postes = await ApiService.getUCPostesFiltres(sousCategorie: "Maison Ménager", codeIndividu: widget.codeIndividu, annee: "2025");
      for (final p in postes.where((p) => p.idBien == widget.idBien)) {
        await ApiService.deleteUCPoste(p.idUsage);
      }
      setState(() {
        equipements.clear();
        hasPostesExistants = false;
      });
    }
  }

  Widget buildLine(PosteEquipement p, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(p.nomEquipement, style: const TextStyle(fontSize: 12))),
          IconButton(
            icon: const Icon(Icons.remove, size: 14),
            onPressed:
                () => setState(() {
                  if (p.quantite > 0) p.quantite--;
                  recalculerTotal();
                }),
          ),
          Text('${p.quantite}', style: const TextStyle(fontSize: 12)),
          IconButton(
            icon: const Icon(Icons.add, size: 14),
            onPressed:
                () => setState(() {
                  p.quantite++;
                  recalculerTotal();
                }),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextFormField(
              initialValue: p.anneeAchat.toString(),
              textAlign: TextAlign.center,
              onChanged:
                  (v) => setState(() {
                    final a = int.tryParse(v);
                    if (a != null) p.anneeAchat = a;
                    recalculerTotal();
                  }),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return BaseScreen(
      title: const Text("Équipements ménagers", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      children: [
        CustomCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Empreinte annuelle estimée", style: TextStyle(fontSize: 12)),
              Text("${totalEmission.toStringAsFixed(0)} kgCO₂", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CustomCard(child: Column(children: equipements.asMap().entries.map((e) => buildLine(e.value, e.key)).toList())),
        const SizedBox(height: 12),
        if (hasPostesExistants)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: supprimer, child: const Text("Supprimer", style: TextStyle(fontSize: 12))),
              ElevatedButton(onPressed: enregistrer, child: const Text("Mettre à jour", style: TextStyle(fontSize: 12))),
            ],
          )
        else
          Center(child: ElevatedButton(onPressed: enregistrer, child: const Text("Enregistrer", style: TextStyle(fontSize: 12)))),
      ],
    );
  }
}
