import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../data/services/api_service.dart';
import '../../core/utils/const_construction.dart';

class BienImmobilier {
  String type;
  double surface;
  int anneeConstruction;
  int nbProprietaires;
  double surfaceGarage;
  bool garage;
  bool piscine;
  String typePiscine;
  double piscineLongueur;
  double piscineLargeur;
  bool abriEtSerre;
  double surfaceAbriEtSerre;

  BienImmobilier({
    required this.type,
    this.surface = 100,
    this.anneeConstruction = 2010,
    this.nbProprietaires = 1,
    this.surfaceGarage = 30,
    this.garage = false,
    this.piscine = false,
    this.typePiscine = "Piscine béton",
    this.piscineLongueur = 4,
    this.piscineLargeur = 2.5,
    this.abriEtSerre = false,
    this.surfaceAbriEtSerre = 10,
  });
}

class ConstructionScreen extends StatefulWidget {
  const ConstructionScreen({super.key});

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  final BienImmobilier bien = BienImmobilier(type: "Maison Classique");

  Map<String, double> facteursEmission = {};
  Map<String, int> dureesAmortissement = {};
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    loadEquipementsData();
  }

  Future<void> loadEquipementsData() async {
    print("🔄 Chargement des données d'équipements...");
    try {
      final equipements = await ApiService.getRefEquipements();
      print("✅ Données d'équipements récupérées : $equipements");

      final Map<String, double> facteurs = {};
      final Map<String, int> durees = {};

      for (var e in equipements) {
        final nom = e['Nom_Equipement'];
        final facteur =
            double.tryParse(
              e['Valeur_Emission_Grise'].toString().replaceAll(',', '.'),
            ) ??
            0;
        final duree = int.tryParse(e['Duree_Amortissement'].toString()) ?? 1;
        facteurs[nom] = facteur;
        durees[nom] = duree;
      }

      setState(() {
        facteursEmission = facteurs;
        dureesAmortissement = durees;
        isLoading = false;
        errorMsg = null;
        print("✅ Données chargées (${facteursEmission.length})");
        print(
          "Clés disponibles dans facteursEmission : ${facteursEmission.keys}",
        );
      });
    } catch (e) {
      print("❌ Erreur chargement équipements : $e");
      setState(() {
        isLoading = false;
        errorMsg = "Erreur lors du chargement des équipements";
      });
    }
  }

  double calculerTotalEmission() {
    final reduction = reductionParAnnee(bien.anneeConstruction);
    print("Réduction par année : $reduction");

    double total = 0.0;

    total +=
        (bien.surface * (facteursEmission[bien.type] ?? 0) * reduction) /
        (dureesAmortissement[bien.type] ?? 1) /
        bien.nbProprietaires;

    print("Total après type principal : $total");

    if (bien.garage) {
      total +=
          (bien.surfaceGarage *
              (facteursEmission['Garage béton'] ?? 0) *
              reduction) /
          (dureesAmortissement['Garage béton'] ?? 1) /
          bien.nbProprietaires;
      print("Total après garage : $total");
    }

    if (bien.piscine) {
      final surfacePiscine = bien.piscineLargeur * bien.piscineLongueur;
      total +=
          (surfacePiscine *
              (facteursEmission[bien.typePiscine] ?? 0) *
              reduction) /
          (dureesAmortissement[bien.typePiscine] ?? 1) /
          bien.nbProprietaires;
      print("Total après piscine : $total");
    }

    if (bien.abriEtSerre) {
      total +=
          (bien.surfaceAbriEtSerre *
              (facteursEmission['Abri de jardin bois'] ?? 0) *
              reduction) /
          (dureesAmortissement['Abri de jardin bois'] ?? 1) /
          bien.nbProprietaires;
      print("Total après abri/serre : $total");
    }

    return total;
  }

  Widget champ(
    String label,
    double value,
    Function(double) onChanged, {
    bool allowDecimal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged:
            (val) => onChanged(double.tryParse(val.replaceAll(',', '.')) ?? 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("🧩 isLoading = $isLoading | errorMsg = $errorMsg");

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMsg != null) {
      return Center(
        child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
      );
    }

    return BaseScreen(
      title: "Construction du logement",
      children: [
        CustomCard(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value:
                      facteursEmission.keys.contains(bien.type)
                          ? bien.type
                          : null,
                  isExpanded: true,
                  items:
                      facteursEmission.keys
                          .where(
                            (k) =>
                                k.contains("Maison") ||
                                k.contains("Appartement"),
                          )
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => bien.type = val!),
                ),
                champ(
                  "Surface (m²)",
                  bien.surface,
                  (v) => setState(() => bien.surface = v),
                ),
                champ(
                  "Année de construction",
                  bien.anneeConstruction.toDouble(),
                  (v) => setState(() => bien.anneeConstruction = v.toInt()),
                ),
                champ(
                  "Nb. propriétaires",
                  bien.nbProprietaires.toDouble(),
                  (v) => setState(() => bien.nbProprietaires = v.toInt()),
                ),
                const Divider(),
                CheckboxListTile(
                  title: const Text("J’ai un garage"),
                  value: bien.garage,
                  onChanged: (val) => setState(() => bien.garage = val!),
                ),
                if (bien.garage)
                  champ(
                    "Surface garage (m²)",
                    bien.surfaceGarage,
                    (v) => setState(() => bien.surfaceGarage = v),
                  ),
                const Divider(),
                CheckboxListTile(
                  title: const Text("J’ai une piscine"),
                  value: bien.piscine,
                  onChanged: (val) => setState(() => bien.piscine = val!),
                ),
                if (bien.piscine) ...[
                  DropdownButton<String>(
                    value: bien.typePiscine,
                    isExpanded: true,
                    items:
                        ["Piscine béton", "Piscine coque"]
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => bien.typePiscine = val!),
                  ),
                  champ(
                    "Longueur piscine (m)",
                    bien.piscineLongueur,
                    (v) => setState(() => bien.piscineLongueur = v),
                    allowDecimal: true,
                  ),
                  champ(
                    "Largeur piscine (m)",
                    bien.piscineLargeur,
                    (v) => setState(() => bien.piscineLargeur = v),
                    allowDecimal: true,
                  ),
                ],
                const Divider(),
                CheckboxListTile(
                  title: const Text(
                    "J’ai une construction dans mon jardin (abri ou serre)",
                  ),
                  value: bien.abriEtSerre,
                  onChanged: (val) => setState(() => bien.abriEtSerre = val!),
                ),
                if (bien.abriEtSerre)
                  champ(
                    "Surface abri/serre (m²)",
                    bien.surfaceAbriEtSerre,
                    (v) => setState(() => bien.surfaceAbriEtSerre = v),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text("Recalculer"),
                ),
                Text(
                  "Émission estimée : ${calculerTotalEmission().toStringAsFixed(1)} kg CO₂e/an",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
