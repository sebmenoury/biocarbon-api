import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../poste_list_screen.dart';
import '../usage_logement/poste_usage.dart';
import 'poste_voiture.dart';

class DeplacementVoitureScreen extends StatefulWidget {
  final String codeIndividu;
  final VoidCallback onSave;
  final String sousCategorie;
  final String valeurTemps;

  const DeplacementVoitureScreen({super.key, required this.codeIndividu, required this.sousCategorie, required this.valeurTemps, required this.onSave});

  @override
  State<DeplacementVoitureScreen> createState() => _DeplacementVoitureScreenState();
}

class _DeplacementVoitureScreenState extends State<DeplacementVoitureScreen> {
  List<PosteVoiture> usages = [];
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

    final existants = postes.where((p) => p.sousCategorie == 'Déplacements Voiture').toList();
    hasPostesExistants = existants.isNotEmpty;
    final nomsExistants = existants.map((e) => e.nomPoste).toSet();
    List<PosteVoiture> resultat = [];

    final refFiltree = ref.where((e) => e['Sous_Categorie'] == 'Déplacements Voiture').toList();

    for (final r in refFiltree) {
      final nom = r['Nom_Usage'];
      if (nomsExistants.contains(nom)) continue;
      resultat.add(
        PosteVoiture(nomUsage: nom, valeur: 0, unite: r['Unite'] ?? 'km/an', facteurEmission: double.tryParse(r['Valeur_Emission_Unitaire'].toString()) ?? 0, consoL100: 6.0, personnes: 1.0),
      );
    }

    for (final p in existants) {
      final refMatch = refFiltree.firstWhere((e) => e['Nom_Usage'] == p.nomPoste, orElse: () => {});
      resultat.add(
        PosteVoiture(
          nomUsage: p.nomPoste ?? 'Inconnu',
          valeur: (p.quantite ?? 0).toDouble(),
          unite: refMatch['Unite'] ?? 'km/an',
          facteurEmission: double.tryParse(refMatch['Valeur_Emission_Unitaire'].toString()) ?? 0,
          idUsageInitial: p.idUsage,
          consoL100: double.tryParse(p.frequence ?? '6.0') ?? 6.0, // ici stocké dans fréquence
          personnes: p.nbPersonnes ?? 1.0,
        ),
      );
    }

    setState(() {
      usages = resultat;
      recalculerTotal();
      isLoading = false;
    });
  }

  double calculerEmissionVoiture() {
    return (valeur * consoL100 / 100 * facteurEmission) / (personnes > 0 ? personnes : 1);
  }

  void recalculerTotal() {
    totalEmission = usages.fold(0.0, (s, u) => s + u.calculerEmissionVoiture());
  }

  Future<void> enregistrer() async {
    final codeIndividu = widget.codeIndividu;
    final valeurTemps = widget.valeurTemps;
    final sousCategorie = widget.sousCategorie;

    await ApiService.deleteAllPostesSansBiensousCategory(codeIndividu: codeIndividu, valeurTemps: valeurTemps, sousCategorie: sousCategorie);
    final List<Map<String, dynamic>> payloads = [];
    final nowIso = DateTime.now().toIso8601String();

    for (final u in usages) {
      if (u.valeur > 0) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final idUsage = "TEMP-\${timestamp}_\${sousCategorie}_\${u.nomUsage}_\${valeurTemps}".replaceAll(' ', '_');

        payloads.add({
          "ID_Usage": idUsage,
          "Code_Individu": codeIndividu,
          "Type_Temps": "Réel",
          "Valeur_Temps": valeurTemps,
          "Date_enregistrement": nowIso,
          "ID_Bien": "",
          "Type_Bien": "",
          "Type_Poste": "Usage",
          "Type_Categorie": "Déplacements",
          "Sous_Categorie": sousCategorie,
          "Nom_Poste": u.nomUsage,
          "Nom_Logement": "",
          "Quantite": u.valeur,
          "Unite": "km/an",
          "Frequence": u.consoL100.toString(),
          "Nb_Personne": u.personnes,
          "Facteur_Emission": u.facteurEmission,
          "Emission_Calculee": u.calculerEmissionVoiture(),
          "Mode_Calcul": "Personnalisé",
          "Annee_Achat": "",
          "Duree_Amortissement": "",
          "Nb_Personnes": u.personnes,
        });
      }
    }

    if (payloads.isNotEmpty) await ApiService.savePostesBulk(payloads);
    widget.onSave();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Données enregistrées")));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PosteListScreen(codeIndividu: codeIndividu, sousCategorie: sousCategorie, typeCategorie: "Déplacements", valeurTemps: valeurTemps)),
    );
  }

  Future<void> supprimer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Supprimer ?"),
            content: const Text("Souhaitez-vous supprimer toutes les informations concernant vos déplacements en voiture ?"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer"))],
          ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteAllPostesSansBiensousCategory(codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps, sousCategorie: widget.sousCategorie);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Tous les déplacements voiture ont été supprimés")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PosteListScreen(codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps, sousCategorie: widget.sousCategorie, typeCategorie: "Déplacements")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Erreur lors de la suppression : $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Stack(
        alignment: Alignment.center,
        children: [
          const Text("Déclaration de vos déplacements voiture", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            child: Text("🚗 Renseignez le kilométrage annuel, la consommation de votre véhicule (en L/100km) et le nombre moyen de personnes à bord.", style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(height: 12),
          CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.electric_car, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text("Empreinte totale", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("${totalEmission.toStringAsFixed(0)} kgCO₂", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...usages.map(
            (u) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.nomUsage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text("Km annuels", style: TextStyle(fontSize: 10)),
                            TextFormField(
                              initialValue: u.valeur.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged:
                                  (val) => setState(() {
                                    u.valeur = double.tryParse(val) ?? 0;
                                    recalculerTotal();
                                  }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            const Text("Conso L/100km", style: TextStyle(fontSize: 10)),
                            TextFormField(
                              initialValue: u.consoL100.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged:
                                  (val) => setState(() {
                                    u.consoL100 = double.tryParse(val) ?? 6.0;
                                    recalculerTotal();
                                  }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            const Text("Personnes à bord", style: TextStyle(fontSize: 10)),
                            TextFormField(
                              initialValue: u.personnes.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged:
                                  (val) => setState(() {
                                    u.personnes = double.tryParse(val) ?? 1.0;
                                    recalculerTotal();
                                  }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
