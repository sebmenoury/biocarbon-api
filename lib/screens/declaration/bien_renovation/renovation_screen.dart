import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../data/classes/poste_postes.dart';
import '../../../data/classes/post_helper.dart';
import '../poste_list_screen.dart';
import '../eqt_equipements/poste_equipement.dart';

class CustomNumberInput extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  final String label;
  final int min;
  final int max;
  final String suffix;

  const CustomNumberInput({super.key, required this.value, required this.onChanged, required this.label, this.min = 0, this.max = 9999, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        IconButton(icon: const Icon(Icons.remove), onPressed: value > min ? () => onChanged(value - 1) : null),
        Text('$value$suffix'),
        IconButton(icon: const Icon(Icons.add), onPressed: value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

class RenovationScreen extends StatefulWidget {
  final String idBien;
  final String codeIndividu;
  final String valeurTemps;
  final VoidCallback onSave;

  const RenovationScreen({super.key, required this.idBien, required this.codeIndividu, required this.valeurTemps, required this.onSave});

  @override
  State<RenovationScreen> createState() => _RenovationScreenState();
}

class _RenovationScreenState extends State<RenovationScreen> {
  Map<String, dynamic> bien = {};
  List<PosteEquipement> equipements = [];
  double totalEmission = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    // 🔹 Chargement du bien
    bien = await ApiService.getBienParId(widget.codeIndividu, widget.idBien);
    final denomination = bien['Dénomination'] ?? '';
    final typeBien = bien['Type_Bien'] ?? '';
    final nbProprietaires = int.tryParse(bien['Nb_Proprietaires']?.toString() ?? '1') ?? 1;

    // 🔹 Données de référence
    final ref = await ApiService.getRefEquipements();
    final refFiltree = ref.where((e) => e['Type_Categorie'] == 'Logement' && e['Sous_Categorie'] == 'Rénovation').toList();

    // 🔹 Postes existants
    final postes = await ApiService.getUCPostesFiltres(idBien: widget.idBien);
    final existants = postes.where((p) => p.sousCategorie == 'Rénovation').toList();
    final nomsExistants = existants.map((e) => e.nomPoste).toSet();

    List<PosteEquipement> resultat = [];

    // 🔹 Nouveaux équipements (pas encore déclarés)
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

    // 🔹 Équipements existants
    for (final p in existants) {
      final refMatch = ref.firstWhere((e) => e['Nom_Equipement'] == p.nomPoste, orElse: () => {});
      resultat.add(
        PosteEquipement(
          nomEquipement: p.nomPoste!,
          quantite: p.quantite != null ? p.quantite!.round() : 0,
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

    resultat.sort((a, b) {
      if (a.quantite > 0 && b.quantite == 0) return -1;
      if (a.quantite == 0 && b.quantite > 0) return 1;
      return 0;
    });

    setState(() {
      equipements = resultat;
      isLoading = false;
    });

    recalculeTotal();
  }

  void recalculeTotal() {
    double total = 0.0;

    for (final e in equipements) {
      if (e.quantite > 0 && e.facteurEmission > 0 && e.dureeAmortissement > 0) {
        final emission = e.quantite * e.facteurEmission / e.dureeAmortissement;
        total += emission / (e.nbProprietaires > 0 ? e.nbProprietaires : 1);
      }
    }

    setState(() {
      totalEmission = total;
    });
  }

  Future<void> enregistrer() async {
    final codeIndividu = widget.codeIndividu;
    final valeurTemps = widget.valeurTemps;
    final sousCategorie = "Rénovation";

    // 🔁 Supprimer les anciens postes liés à ce bien et cette sous-catégorie
    await ApiService.deleteAllPostes(codeIndividu: codeIndividu, idBien: widget.idBien, valeurTemps: valeurTemps, sousCategorie: sousCategorie);

    final nowIso = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> payloads = [];

    for (int i = 0; i < equipements.length; i++) {
      final e = equipements[i];

      if (e.quantite > 0) {
        final idUsage = "${widget.idBien}_${e.nomEquipement}_${e.anneeAchat}".replaceAll(' ', '_');

        payloads.add({
          "ID_Usage": idUsage,
          "Code_Individu": codeIndividu,
          "Type_Temps": "Réel",
          "Valeur_Temps": valeurTemps,
          "Date_enregistrement": nowIso,
          "ID_Bien": e.idBien,
          "Type_Bien": e.typeBien,
          "Type_Poste": "Equipement",
          "Type_Categorie": "Logement",
          "Sous_Categorie": sousCategorie,
          "Nom_Poste": e.nomEquipement,
          "Nom_Logement": e.nomLogement,
          "Quantite": e.quantite,
          "Unite": "m2",
          "Frequence": "",
          "Facteur_Emission": e.facteurEmission,
          "Emission_Calculee": (e.facteurEmission * e.quantite / e.dureeAmortissement),
          "Mode_Calcul": "Amorti",
          "Annee_Achat": e.anneeAchat,
          "Duree_Amortissement": e.dureeAmortissement,
        });
      }
    }

    // ✅ Envoi groupé
    if (payloads.isNotEmpty) {
      await ApiService.savePostesBulk(payloads);
    }

    widget.onSave();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Travaux de rénovation enregistrés")));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Logement", sousCategorie: sousCategorie, codeIndividu: codeIndividu, valeurTemps: valeurTemps)),
    );
  }

  Future<void> supprimer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Supprimer ?"),
            content: const Text("Supprimer toutes les rénovations de ce bien ?"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer"))],
          ),
    );

    if (confirm == true) {
      await ApiService.deleteAllPostes(codeIndividu: widget.codeIndividu, idBien: widget.idBien, valeurTemps: widget.valeurTemps, sousCategorie: "Rénovation");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Rénovations supprimées")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Logement", sousCategorie: "Rénovation", codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Rénovation")),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(
          children: [
            CustomCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text("Total kg CO₂/an", style: TextStyle(fontSize: 12)), Text(calculTotal().toStringAsFixed(0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))],
              ),
            ),
            const SizedBox(height: 12),
            for (final ref in equipements)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref.nomEquipement, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: CustomNumberInput(
                            label: "Surface (m²)",
                            value: ref.quantite,
                            onChanged: (val) {
                              setState(() => ref.quantite = val);
                              recalculeTotal();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomNumberInput(
                            label: "Année",
                            value: ref.anneeAchat,
                            onChanged: (val) {
                              setState(() => ref.anneeAchat = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [ElevatedButton(onPressed: enregistrer, child: const Text("Enregistrer")), OutlinedButton(onPressed: supprimer, child: const Text("Supprimer la déclaration"))],
            ),
          ],
        ),
      ),
    );
  }

  double calculTotal() {
    double total = 0.0;

    for (final e in equipements) {
      final quantite = e.quantite;
      final facteur = e.facteurEmission;
      final duree = e.dureeAmortissement > 0 ? e.dureeAmortissement : 30;
      final nbProps = e.nbProprietaires > 0 ? e.nbProprietaires : 1;

      if (quantite > 0 && facteur > 0) {
        final emission = (quantite * facteur) / duree;
        total += emission / nbProps;
      }
    }

    return total;
  }
}
