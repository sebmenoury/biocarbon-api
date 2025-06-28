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
    final refFiltree = ref.where((e) => e['Type_Categorie'] == 'Biens et services' && e['Sous_Categorie'] == widget.sousCategorie).toList();
    final postes = await ApiService.getUCPostesFiltres(idBien: widget.idBien);
    final existants = postes.where((p) => p.sousCategorie == widget.sousCategorie).toList();
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
    // Trie : équipements déclarés (quantité > 0) en haut
    resultat.sort((a, b) {
      if (a.quantite > 0 && b.quantite == 0) return -1;
      if (a.quantite == 0 && b.quantite > 0) return 1;
      return 0;
    });

    setState(() {
      equipements = resultat;
      recalculerTotal();
      isLoading = false;
    });
  }

  double calculerEmission(PosteEquipement p) {
    final e = (p.quantite * p.facteurEmission) / p.dureeAmortissement / p.nbProprietaires;
    return e.isNaN ? 0 : e;
  }

  void recalculerTotal() {
    totalEmission = equipements.fold(0.0, (s, p) => s + calculerEmission(p));
  }

  Future<void> enregistrer() async {
    final codeIndividu = widget.codeIndividu;
    final valeurTemps = "2025";
    final sousCategorie = widget.sousCategorie;

    await ApiService.deleteAllPostes(codeIndividu: codeIndividu, idBien: widget.idBien, valeurTemps: valeurTemps, sousCategorie: sousCategorie);

    final nowIso = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> payloads = [];

    for (int i = 0; i < equipements.length; i++) {
      final e = equipements[i];
      if (e.quantite > 0) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final idUsage = "TEMP-${timestamp}_${sousCategorie}_${e.nomEquipement}_${e.anneeAchat}".replaceAll(' ', '_');

        payloads.add({
          "ID_Usage": idUsage,
          "Code_Individu": codeIndividu,
          "Type_Temps": "Réel",
          "Valeur_Temps": valeurTemps,
          "Date_enregistrement": nowIso,
          "ID_Bien": e.idBien,
          "Type_Bien": e.typeBien,
          "Type_Poste": "Equipement",
          "Type_Categorie": "Biens et services",
          "Sous_Categorie": sousCategorie,
          "Nom_Poste": e.nomEquipement,
          "Nom_Logement": e.nomLogement,
          "Quantite": e.quantite,
          "Unite": "unité",
          "Frequence": "",
          "Facteur_Emission": e.facteurEmission,
          "Emission_Calculee": calculerEmission(e),
          "Mode_Calcul": "Amorti",
          "Annee_Achat": e.anneeAchat,
          "Duree_Amortissement": e.dureeAmortissement,
        });
      }
    }

    if (payloads.isNotEmpty) {
      await ApiService.savePostesBulk(payloads); // ⬅️ à implémenter si pas encore fait
    }

    widget.onSave();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Équipements enregistrés")));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Biens et services", sousCategorie: sousCategorie, codeIndividu: codeIndividu, valeurTemps: valeurTemps)),
    );
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
      await ApiService.deleteAllPostes(codeIndividu: widget.codeIndividu, idBien: widget.idBien, valeurTemps: "2025", sousCategorie: widget.sousCategorie);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Tous les équipements ont été supprimés")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Biens et services", sousCategorie: widget.sousCategorie, codeIndividu: widget.codeIndividu, valeurTemps: "2025")),
      );
    }
  }

  Widget buildEquipementLine(PosteEquipement poste, int index) {
    final isActive = poste.quantite > 0;
    final colorBloc = isActive ? Colors.white : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Nom de l'équipement
          Expanded(flex: 2, child: Text(poste.nomEquipement, style: const TextStyle(fontSize: 12))),

          // Bloc quantité avec + / -
          Container(
            width: 60,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: colorBloc, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (poste.quantite > 1) {
                        poste.quantite--;
                      } else {
                        final doublons = equipements.where((p) => p.nomEquipement == poste.nomEquipement).toList();
                        if (doublons.length > 1) {
                          equipements.removeAt(index);
                        } else {
                          poste.quantite = 0;
                        }
                      }
                      recalculerTotal();
                    });
                  },
                  child: const Icon(Icons.remove, size: 14),
                ),
                Text('${poste.quantite}', style: const TextStyle(fontSize: 12)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (poste.quantite == 0) {
                        poste.quantite = 1;
                      } else {
                        equipements.insert(index + 1, PosteEquipement.clone(poste));
                      }
                      recalculerTotal();
                    });
                  },
                  child: const Icon(Icons.add, size: 14),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Bloc année d'achat avec + / -
          Container(
            width: 90,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: colorBloc, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      poste.anneeAchat--;
                      recalculerTotal();
                    });
                  },
                  child: const Icon(Icons.remove, size: 14),
                ),
                SizedBox(
                  width: 40,
                  height: 24,
                  child: TextFormField(
                    key: ValueKey(poste.anneeAchat),
                    initialValue: poste.anneeAchat.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6)),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final an = int.tryParse(val);
                      if (an != null) {
                        setState(() {
                          poste.anneeAchat = an;
                          recalculerTotal();
                        });
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      poste.anneeAchat++;
                      recalculerTotal();
                    });
                  },
                  child: const Icon(Icons.add, size: 14),
                ),
              ],
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
      title: Stack(
        alignment: Alignment.center,
        children: [
          Text("Déclarer mes  ${widget.sousCategorie?.toLowerCase() ?? ''}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context)),
          ),
        ],
      ),
      children: [
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Empreinte d'amortissement annuel", style: TextStyle(fontSize: 12)),
              Text("${totalEmission.toStringAsFixed(0)} kgCO₂", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CustomCard(child: Column(children: equipements.asMap().entries.map((e) => buildEquipementLine(e.value, e.key)).toList())),
        const SizedBox(height: 12),
        if (hasPostesExistants)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: supprimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  minimumSize: const Size(120, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Supprimer", style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                onPressed: enregistrer,
                icon: const Icon(Icons.update, size: 14),
                label: const Text("Mettre à jour", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[900],
                  minimumSize: const Size(120, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          )
        else
          Center(
            child: ElevatedButton.icon(
              onPressed: enregistrer,
              icon: const Icon(Icons.save, size: 14),
              label: const Text("Enregistrer", style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[900],
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
      ],
    );
  }
}
