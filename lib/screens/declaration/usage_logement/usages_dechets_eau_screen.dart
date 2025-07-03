import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../poste_list_screen.dart';
import 'poste_usage.dart';

class UsagesDechetsEauScreen extends StatefulWidget {
  final String codeIndividu;
  final String idBien;
  final VoidCallback onSave;
  final String sousCategorie;
  final String valeurTemps;

  const UsagesDechetsEauScreen({super.key, required this.codeIndividu, required this.idBien, required this.sousCategorie, required this.valeurTemps, required this.onSave});

  @override
  State<UsagesDechetsEauScreen> createState() => _UsagesDechetsEauScreenState();
}

class _UsagesDechetsEauScreenState extends State<UsagesDechetsEauScreen> {
  List<PosteUsage> usages = [];
  bool isLoading = true;
  double totalEmission = 0;
  double nbHabitants = 1; // valeur par défaut
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
    nbHabitants = double.tryParse(bien['Nb_Habitants']?.toString() ?? '1') ?? 1;

    final ref = await ApiService.getRefUsages();
    final postes = await ApiService.getUCPostesFiltres(idBien: widget.idBien);

    final existants = postes.where((p) => p.sousCategorie == 'Déchets et Eau').toList();

    hasPostesExistants = existants.isNotEmpty;

    final nomsExistants = existants.map((e) => e.nomPoste).toSet();

    List<PosteUsage> resultat = [];

    final refFiltree = ref.where((e) => e['Sous_Categorie'] == 'Déchets et Eau').toList();

    // Boucle sur les postes référentiels qui ne sont pas encore déclarés
    // Boucle sur les postes référentiels qui ne sont pas encore déclarés
    for (final r in refFiltree) {
      final nom = r['Nom_Usage'];

      if (nomsExistants.contains(nom)) continue;

      // Valeurs par défaut spécifiques
      double valeurInitiale = 0;
      if (nom == 'Déchets ménagers') {
        valeurInitiale = 590 * nbHabitants;
      } else if (nom == 'Eau domestique') {
        valeurInitiale = 53 * nbHabitants;
      }

      resultat.add(
        PosteUsage(
          nomUsage: nom,
          valeur: valeurInitiale,
          unite: r['Unite'] ?? 'kWh',
          facteurEmission: double.tryParse(r['Valeur_Emission_Unitaire'].toString()) ?? 0,
          idBien: widget.idBien,
          typeBien: typeBien,
          nomLogement: denomination,
          nbHabitants: nbHabitants,
        ),
      );
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
          idBien: widget.idBien,
          typeBien: typeBien,
          nomLogement: denomination,
          nbHabitants: nbHabitants,
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
    totalEmission = usages.fold(0.0, (s, u) => s + u.calculerEmission(nbHabitants));
  }

  Future<void> enregistrer() async {
    final codeIndividu = widget.codeIndividu;
    final valeurTemps = "2025";
    final sousCategorie = widget.sousCategorie;

    await ApiService.deleteAllPostes(codeIndividu: widget.codeIndividu, idBien: widget.idBien, valeurTemps: valeurTemps, sousCategorie: sousCategorie);
    final List<Map<String, dynamic>> payloads = [];
    final nowIso = DateTime.now().toIso8601String();

    for (int i = 0; i < usages.length; i++) {
      final u = usages[i];
      if (u.valeur > 0) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final idUsage = "TEMP-${timestamp}_${sousCategorie}_${u.nomUsage}_${valeurTemps}".replaceAll(' ', '_');

        // Choix de l’unité selon le nom de l’usage
        String uniteposte = "kg déchets/an";
        if (u.nomUsage.toLowerCase().contains("Eau")) {
          uniteposte = "m³/an";
        }

        payloads.add({
          "ID_Usage": idUsage,
          "Code_Individu": codeIndividu,
          "Type_Temps": "Réel",
          "Valeur_Temps": valeurTemps,
          "Date_enregistrement": nowIso,
          "ID_Bien": u.idBien,
          "Type_Bien": u.typeBien,
          "Type_Poste": "Usage",
          "Type_Categorie": "Logement",
          "Sous_Categorie": sousCategorie,
          "Nom_Poste": u.nomUsage,
          "Nom_Logement": u.nomLogement,
          "Quantite": u.valeur,
          "Unite": uniteposte,
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
      MaterialPageRoute(builder: (_) => PosteListScreen(codeIndividu: widget.codeIndividu, sousCategorie: sousCategorie, typeCategorie: "Logement", valeurTemps: valeurTemps)),
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
      await ApiService.deleteAllPostes(codeIndividu: widget.codeIndividu, idBien: widget.idBien, valeurTemps: widget.valeurTemps, sousCategorie: widget.sousCategorie);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Tous les équipements ont été supprimés")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Logement", sousCategorie: widget.sousCategorie, codeIndividu: widget.codeIndividu, valeurTemps: "2025")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Stack(
        alignment: Alignment.center,
        children: [
          const Text("Déclaration de votre consommation eau et déchets", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            child: const Text(
              "⚙️ Les valeurs proposées sont basées sur des ordres de grandeur moyens constatés en France, appliquées au nombre d'habitants du logement, sachant que :\n"
              "• Déchets : chaque personne génère en moyenne 590 kg de déchets ménagers par an.\n"
              "• Eau : la consommation domestique annuelle moyenne est d’environ 53 m³ par habitant.\n\n"
              "Point d'attention : les quantités déclarées sont celles du foyer, et sont divisées par le nombre d'habitants du logement pour obtenir l'empreinte individuelle.",
              style: TextStyle(fontSize: 11),
              textAlign: TextAlign.justify,
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
                Text("Indication de consommation par défaut", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),

                Column(
                  children:
                      usages.map((u) {
                        // Choix de l’unité selon le nom de l’usage
                        String uniteAffichee = "kg déchets/an";
                        if (u.nomUsage.toLowerCase().contains("eau")) {
                          uniteAffichee = "m³/an";
                        }

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
                                    child: Text(uniteAffichee, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
