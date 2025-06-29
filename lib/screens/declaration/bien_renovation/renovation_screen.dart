import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../ui/widgets/custom_number_input.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../data/classes/poste_postes.dart';
import '../../../data/classes/post_helper.dart';
import '../bien_immobilier/bien_list_screen.dart';
import '..//poste_list_screen.dart';

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
  List<Map<String, dynamic>> refEquipements = [];
  List<Map<String, dynamic>> postesExistants = [];

  final Map<String, TextEditingController> surfaceControllers = {};
  final Map<String, TextEditingController> anneeControllers = {};
  final Map<String, String?> idUsageExistants = {};
  final Map<String, int> anneeInitiale = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    // 🔹 1. Chargement des données de référence et du bien
    final bienData = await ApiService.getBienParId(widget.idBien, widget.codeIndividu);
    final ref = await ApiService.getRefEquipements();
    final refFiltree = ref.where((e) => e['Type_Categorie'] == 'Logement' && e['Sous_Categorie'] == 'Rénovation').toList();

    refEquipements = refFiltree;
    bien = bienData;

    // 🔹 2. Chargement des postes existants liés à ce bien pour l’année et la sous-catégorie Rénovation
    final List<Poste> tousPostes = await ApiService.getUCPostesFiltres(codeIndividu: widget.codeIndividu, idBien: widget.idBien, sousCategorie: 'Rénovation', annee: widget.valeurTemps);

    final List<Poste> postesRenovation = tousPostes.where((p) => p.idBien?.toString() == widget.idBien).toList();

    postesExistants = postesRenovation.map((p) => {'ID_Usage': p.idUsage, 'Nom_Poste': p.nomPoste, 'Quantite': p.quantite, 'Annee_Achat': p.anneeAchat}).toList();

    debugPrint("🔧 ${postesRenovation.length} postes Rénovation trouvés");

    // 🔹 3. Initialisation des contrôleurs
    for (final refEq in refEquipements) {
      final usage = refEq['Nom_Equipement'];

      final match = postesRenovation.firstWhere(
        (p) => p.nomPoste == usage,
        orElse:
            () => Poste(
              idUsage: '', // temporaire, car pas encore connu
              typeCategorie: 'Logement',
              sousCategorie: 'Rénovation',
              typePoste: 'Poste',
              nomPoste: usage,
              idBien: widget.idBien,
              typeBien: bien['Type_Bien'] ?? '',
              quantite: 0,
              unite: 'm2',
              emissionCalculee: 0,
              frequence: '',
              anneeAchat: DateTime.now().year,
              dureeAmortissement: 0,
            ),
      );

      surfaceControllers[usage] = TextEditingController(text: match.quantite.toString());
      anneeControllers[usage] = TextEditingController(text: match.anneeAchat.toString());

      idUsageExistants[usage] = match.idUsage;
      anneeInitiale[usage] = match.anneeAchat ?? DateTime.now().year;
    }

    setState(() => isLoading = false);
  }

  Future<void> enregistrer() async {
    for (final refEq in refEquipements) {
      final usage = refEq['Nom_Usage'];
      final quantite = int.tryParse(surfaceControllers[usage]?.text ?? '') ?? 0;
      final annee = int.tryParse(anneeControllers[usage]?.text ?? '') ?? DateTime.now().year;
      final newIdUsage = "${widget.idBien}_${usage}_$annee".replaceAll(' ', '_');

      final emission = (refEq['Facteur_Emission'] ?? 0.0) * quantite / (refEq['Duree'] ?? 30);

      final data = {
        "Code_Individu": widget.codeIndividu,
        "Type_Temps": "Réel",
        "Valeur_Temps": widget.valeurTemps,
        "ID_Bien": widget.idBien,
        "Nom_Logement": bien['Dénomination'] ?? '',
        "Type_Bien": bien['Type_Bien'] ?? '',
        "Type_Poste": "Equipement",
        "Type_Categorie": "Logement",
        "Sous_Categorie": "Rénovation",
        "Nom_Poste": usage,
        "Quantite": quantite,
        "Unite": "m2",
        "Facteur_Emission": refEq['Facteur_Emission'],
        "Emission_Calculee": emission,
        "Mode_Calcul": "Amorti",
        "Duree_Amortissement": refEq['Duree'],
        "Annee_Achat": annee,
      };

      await PosteHelper.traiterPoste(posteData: data, idUsageInitial: idUsageExistants[usage], anneeAchatInitiale: anneeInitiale[usage] ?? annee, nouvelleAnneeAchat: annee, newIdUsage: newIdUsage);
    }

    widget.onSave();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Rénovations enregistrées")));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: "Logement", sousCategorie: "Rénovation", codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps)),
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
            for (final ref in refEquipements)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref['Nom_Usage'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: CustomNumberInput(
                            label: "Surface (m²)",
                            value: int.tryParse(surfaceControllers[ref['Nom_Usage']]?.text ?? '') ?? 0,
                            onChanged: (val) {
                              surfaceControllers[ref['Nom_Usage']]?.text = val.toString();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomNumberInput(
                            label: "Année",
                            value: int.tryParse(anneeControllers[ref['Nom_Usage']]?.text ?? '') ?? DateTime.now().year,
                            onChanged: (val) {
                              anneeControllers[ref['Nom_Usage']]?.text = val.toString();
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
    for (final ref in refEquipements) {
      final usage = ref['Nom_Usage'];
      final quantite = int.tryParse(surfaceControllers[usage]?.text ?? '') ?? 0;
      final duree = ref['Duree'] ?? 30;
      final facteur = ref['Facteur_Emission'] ?? 0.0;
      total += (quantite * facteur / duree);
    }
    return total;
  }
}
