import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../poste_list_screen.dart';
import '../usage_logement/poste_usage.dart';

class UsagesLoisirsScreen extends StatefulWidget {
  final String codeIndividu;
  final VoidCallback onSave;
  final String sousCategorie;
  final String valeurTemps;

  const UsagesLoisirsScreen({super.key, required this.codeIndividu, required this.sousCategorie, required this.valeurTemps, required this.onSave});

  @override
  State<UsagesLoisirsScreen> createState() => _UsagesLoisirsScreenState();
}

class _UsagesLoisirsScreenState extends State<UsagesLoisirsScreen> {
  List<PosteUsage> usages = [];
  bool isLoading = true;
  double totalEmission = 0;
  bool hasPostesExistants = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final ref = await ApiService.getRefUsages();
    final postes = await ApiService.getUCPostesFiltres(sousCategorie: widget.sousCategorie, codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps);

    final existants = postes.where((p) => p.sousCategorie == 'Loisirs').toList();

    hasPostesExistants = existants.isNotEmpty;

    final nomsExistants = existants.map((e) => e.nomPoste).toSet();

    List<PosteUsage> resultat = [];

    final refFiltree = ref.where((e) => e['Sous_Categorie'] == 'Loisirs').toList();

    // Boucle sur les postes référentiels qui ne sont pas encore déclarés
    for (final r in refFiltree) {
      final nom = r['Nom_Usage'];

      if (nomsExistants.contains(nom)) continue;

      resultat.add(PosteUsage(nomUsage: nom, valeur: 0, unite: r['Unite'] ?? 'kWh', facteurEmission: double.tryParse(r['Valeur_Emission_Unitaire'].toString()) ?? 0));
    }

    // Boucle sur les postes UC déjà enregistrés
    for (final p in existants) {
      final refMatch = refFiltree.firstWhere((e) => e['Nom_Usage'] == p.nomPoste, orElse: () => {});

      resultat.add(
        PosteUsage(
          nomUsage: p.nomPoste ?? 'Inconnu',
          valeur: (p.quantite ?? 0).toDouble(),
          unite: refMatch['Unite'] ?? 'kWh',
          facteurEmission: double.tryParse(refMatch['Valeur_Emission_Unitaire'].toString()) ?? 0,
          idUsageInitial: p.idUsage,
        ),
      );
    }

    setState(() {
      usages = resultat;
      recalculerTotal();
      isLoading = false;
    });
  }

  void recalculerTotal() {
    totalEmission = usages.fold(0.0, (s, u) => s + u.calculerEmissionLoisir());
  }

  Future<void> enregistrer() async {
    final codeIndividu = widget.codeIndividu;
    final valeurTemps = "2025";
    final sousCategorie = widget.sousCategorie;

    await ApiService.deleteAllPostesSansBiensousCategory(codeIndividu: widget.codeIndividu, valeurTemps: valeurTemps, sousCategorie: sousCategorie);
    final List<Map<String, dynamic>> payloads = [];
    final nowIso = DateTime.now().toIso8601String();

    for (int i = 0; i < usages.length; i++) {
      final u = usages[i];
      if (u.valeur > 0) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final idUsage = "TEMP-${timestamp}_${sousCategorie}_${u.nomUsage}_${valeurTemps}".replaceAll(' ', '_');

        payloads.add({
          "ID_Usage": idUsage,
          "Code_Individu": codeIndividu,
          "Type_Temps": "Réel",
          "Valeur_Temps": valeurTemps,
          "Date_enregistrement": nowIso,
          "ID_Bien": "",
          "Type_Bien": "",
          "Type_Poste": "Usage",
          "Type_Categorie": "Logement",
          "Sous_Categorie": sousCategorie,
          "Nom_Poste": u.nomUsage,
          "Nom_Logement": "",
          "Quantite": u.valeur,
          "Unite": "kWh/an",
          "Frequence": "",
          "Facteur_Emission": u.facteurEmission,
          "Emission_Calculee": u.valeur * u.facteurEmission / u.nbHabitants,
          "Mode_Calcul": "Direct",
          "Annee_Achat": "", // optionnel si non concerné
          "Duree_Amortissement": "", // optionnel si non concerné
        });
      }
    }

    if (payloads.isNotEmpty) await ApiService.savePostesBulk(payloads);
    widget.onSave();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Données enregistrées")));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PosteListScreen(codeIndividu: widget.codeIndividu, sousCategorie: sousCategorie, typeCategorie: "Biens et services", valeurTemps: valeurTemps)),
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
      await ApiService.deleteAllPostesSansBiensousCategory(codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps, sousCategorie: widget.sousCategorie);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Tous les équipements ont été supprimés")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Biens et services", sousCategorie: widget.sousCategorie, codeIndividu: widget.codeIndividu, valeurTemps: "2025")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Stack(
        alignment: Alignment.center,
        children: [
          const Text("Déclaration de vos dépenses loisirs", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context)),
          ),
        ],
      ),

      children: [
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "⚙️ Indiquez ici vos dépenses globales loisirs de l'année, comprenant les vacances, les sorties. \n"
              "Un ratio général est appliqué pour évaluer l'empreinte associée.",
              style: TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.electrical_services, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text("Empreinte totale", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("${totalEmission.toStringAsFixed(0)} kgCO₂", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Relevé de dépenses", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),

                Column(
                  children:
                      usages.map((u) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Padding(padding: const EdgeInsets.only(left: 12), child: Text(u.nomUsage, style: const TextStyle(fontSize: 12)))),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 80,
                                    height: 24,
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                    alignment: Alignment.center,
                                    child: TextFormField(
                                      initialValue: u.valeur.toString(),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                                      onChanged: (val) {
                                        final v = double.tryParse(val) ?? 0;
                                        setState(() {
                                          u.valeur = v;
                                          recalculerTotal();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 70, // largeur fixe pour aligner les unités
                                    child: Text("€/an", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: enregistrer, style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100), child: const Text("Enregistrer", style: TextStyle(color: Colors.black))),
              OutlinedButton(
                onPressed: hasPostesExistants ? supprimer : null,
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.teal.shade200)),
                child: const Text("Supprimer la déclaration", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
