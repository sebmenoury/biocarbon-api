import 'package:flutter/material.dart';
import '../usage_logement/poste_usage.dart';
import '../../../data/services/api_service.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../ui/layout/base_screen.dart';
import "poste_alimentaire.dart";
import 'regime.dart';
import '../poste_list_screen.dart';

class AlimentationScreen extends StatefulWidget {
  final String codeIndividu;
  final String valeurTemps;
  final VoidCallback onSave;

  const AlimentationScreen({super.key, required this.codeIndividu, required this.valeurTemps, required this.onSave});

  @override
  State<AlimentationScreen> createState() => _AlimentationScreenState();
}

class _AlimentationScreenState extends State<AlimentationScreen> {
  double calculerTotalEmission() {
    return aliments.fold(0.0, (total, aliment) {
      if (aliment.frequence != null) {
        return total + (aliment.portion * aliment.frequence! * 52 * aliment.facteur!);
      }
      return total;
    });
  }

  final List<String> labels = ["jamais", "1/mois", "2/mois", "1/sem", "2/sem", "3/sem", "4/sem", "5/sem", "6/sem", "7/sem", "10/sem", "14/sem"];
  final List<double> values = [0, 0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 10, 14];

  String? selectedRegime;
  Map<String, double> frequencesAliments = {};

  Future<List<PosteAlimentaire>> chargerAliments() async {
    final ref = await ApiService.getRefAlimentation();
    final postes = await ApiService.getUCPostesFiltres(codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps, typeCategorie: "Alimentation");

    final Map<String, PosteAlimentaire> mapAliments = {};

    // Étape 1 : on charge tous les aliments de la référence
    for (final r in ref) {
      final nom = r['Nom_Usage'];
      mapAliments[nom] = PosteAlimentaire(
        nom: nom,
        portion: (r['Portion'] as num).toDouble(),
        unite: r['Unite'],
        sousCategorie: r['Sous_Categorie'],
        facteur: (r['Valeur_Emission_Unitaire'] as num).toDouble(),
      );
    }

    // Étape 2 : on applique les fréquences déclarées existantes
    for (final p in postes) {
      final nomPoste = p.nomPoste?.toLowerCase().trim();
      final matchingKey = mapAliments.keys.firstWhere((key) => key.toLowerCase().trim() == nomPoste, orElse: () => '');

      if (matchingKey.isNotEmpty) {
        final valeur = double.tryParse(p.frequence?.toString() ?? '');
        mapAliments[matchingKey]!.frequence = valeur ?? 0;
      }
    }

    return mapAliments.values.toList()..sort((a, b) => a.nom.compareTo(b.nom)); // tri alpha
  }

  List<PosteAlimentaire> aliments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chargerAliments().then((value) {
      setState(() {
        aliments = value;
        isLoading = false;
      });
    });
  }

  Future<void> enregistrerOuMettreAJour() async {
    final codeIndividu = widget.codeIndividu;
    final valeurTemps = widget.valeurTemps;
    const typeCategorie = "Alimentation";

    await ApiService.deleteAllPostesSansBien(codeIndividu: codeIndividu, valeurTemps: valeurTemps, typeCategorie: typeCategorie);

    final nowIso = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> payloads = [];

    for (final a in aliments) {
      final freq = a.frequence;
      if (freq == null || freq == 0) continue;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final idUsage = "TEMP-${timestamp}_${typeCategorie}_${a.nom}_${valeurTemps}".replaceAll(' ', '_');

      final emission = a.portion * freq * 52 * (a.facteur ?? 0);

      payloads.add({
        "ID_Usage": idUsage,
        "Code_Individu": codeIndividu,
        "Type_Temps": "Réel",
        "Valeur_Temps": valeurTemps,
        "Date_enregistrement": nowIso,
        "ID_Bien": null,
        "Type_Bien": null,
        "Type_Poste": "Usage",
        "Type_Categorie": "Alimentation",
        "Sous_Categorie": a.sousCategorie ?? "Autre",
        "Nom_Poste": a.nom,
        "Nom_Logement": null,
        "Quantite": a.portion,
        "Unite": a.unite,
        "Frequence": freq,
        "Facteur_Emission": a.facteur,
        "Emission_Calculee": emission,
        "Mode_Calcul": "Muliplicatif",
        "Annee_Achat": null,
        "Duree_Amortissement": null,
      });
    }

    if (payloads.isNotEmpty) {
      await ApiService.savePostesBulk(payloads);
    }

    widget.onSave();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Déclaration alimentaire enregistrée")));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Alimentation", codeIndividu: codeIndividu, valeurTemps: valeurTemps)));
  }

  Future<void> supprimerPoste() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Supprimer ?"),
            content: const Text("Supprimer tous les postes alimentaires ?"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer"))],
          ),
    );

    if (confirm == true) {
      await ApiService.deleteAllPostesSansBien(codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps, typeCategorie: "Alimentation");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Déclaration supprimée")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Alimentation", codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps)));
    }
  }

  Future<void> choisirRegime(String nom) async {
    final shouldApply = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Utiliser le profil $nom ?"),
            content: const Text("Souhaitez-vous appliquer les fréquences suggérées pour ce régime ?"),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui"))],
          ),
    );

    if (shouldApply == true) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(regimes[nom]!['frequences']);

      for (final aliment in aliments) {
        if (map.containsKey(aliment.nom)) {
          aliment.frequence = (map[aliment.nom] as num).toDouble();
        } else {
          aliment.frequence = null; // ou null si tu préfères
        }
      }
    }

    setState(() {
      selectedRegime = nom;
    });
  }

  Widget buildGroupedCards() {
    final grouped = <String, List<PosteAlimentaire>>{};
    for (var a in aliments) {
      grouped.putIfAbsent(a.sousCategorie ?? 'Autres', () => []).add(a);
    }

    String formatFrequence(double f) {
      switch (f) {
        case 0:
          return "0";
        case 0.25:
          return "¼";
        case 0.5:
          return "½";
        default:
          return f.toInt() == f ? f.toInt().toString() : f.toString();
      }
    }

    return Column(
      children:
          grouped.entries.map((entry) {
            final group = entry.key;
            final alimentsGroupe = entry.value;

            return CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Titre du groupe (ex: Viande)
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(group, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                  // ✅ Ligne des labels de fréquence
                  Padding(
                    padding: const EdgeInsets.only(left: 105), // Aligné avec les ronds
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          values.map((freq) {
                            return SizedBox(width: 14, child: Text(formatFrequence(freq), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)));
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ✅ Liste des aliments avec boutons
                  ...alimentsGroupe.map(
                    (a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [SizedBox(width: 100, child: Text(a.nom, style: const TextStyle(fontSize: 11))), const SizedBox(width: 8), Expanded(child: buildBoutonsFrequence(a))],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget buildBoutonsFrequence(PosteAlimentaire aliment) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(values.length, (i) {
        final actif = aliment.frequence == values[i];
        return Tooltip(
          message: labels[i],
          child: GestureDetector(
            onTap: () {
              setState(() {
                aliment.frequence = values[i];
              });
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400), color: actif ? Colors.green.shade500 : Colors.grey.shade200),
              child: actif ? Center(child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white))) : null,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tousAliments = aliments.map((a) => a.nom).toList()..sort();

    if (isLoading) {
      return const BaseScreen(title: Text("Chargement…", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), child: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: BaseScreen(
          title: Stack(
            alignment: Alignment.center,
            children: [
              const Center(child: Text("Caractéristiques de votre alimentation", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "⚙️ Vous pouvez soit choisir un régime alimentaire type pour initialiser les valeurs de fréquence, soit directement sélectionner les fréquences de consommation de ces aliments.",
                  style: TextStyle(fontSize: 11),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 8),
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        const Text("Empreinte totale", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text("${calculerTotalEmission().toStringAsFixed(0)} kgCO₂/an", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100, left: 8, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text("Initialisez vos valeurs avec un régime alimentaire type", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 6,
                        childAspectRatio: 2.6,
                        children:
                            regimes.entries.map((entry) {
                              final nom = entry.key;
                              final info = entry.value;
                              final selected = selectedRegime == nom;
                              return GestureDetector(
                                onTap: () => choisirRegime(nom),
                                child: CustomCard(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Text(info['emoji'], style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(info['desc'], style: const TextStyle(fontSize: 10))],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text("Indiquez la fréquence de consommation par aliment, par semaine", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      buildGroupedCards(),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: enregistrerOuMettreAJour,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
                            child: const Text("Enregistrer", style: TextStyle(color: Colors.black)),
                          ),
                          OutlinedButton(
                            //
                            //onPressed: hasPostesExistants ? supprimerPoste : null,
                            onPressed: supprimerPoste,
                            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.teal.shade200)),
                            child: const Text("Supprimer la déclaration", style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
