import 'package:flutter/material.dart';
import '../../ui/layout/custom_card.dart';
import '../../data/services/api_service.dart';
import '../../core/utils/const_construction.dart';

class BienImmobilier {
  String id;
  String nom;
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
    required this.id,
    required this.nom,
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
  final BienImmobilier bien;
  final VoidCallback? onSave;
  const ConstructionScreen({super.key, required this.bien, this.onSave});

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  Map<String, double> facteursEmission = {};
  Map<String, int> dureesAmortissement = {};
  bool isLoading = true;
  String? errorMsg;

  BienImmobilier get bien => widget.bien;

  @override
  void initState() {
    super.initState();
    loadEquipementsData();
  }

  Future<void> loadEquipementsData() async {
    try {
      final equipements = await ApiService.getRefEquipements();
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
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = "Erreur lors du chargement des équipements";
      });
    }
  }

  double calculerTotalEmission() {
    final reduction = reductionParAnnee(bien.anneeConstruction);
    double total = 0.0;

    total +=
        (bien.surface * (facteursEmission[bien.type] ?? 0) * reduction) /
        (dureesAmortissement[bien.type] ?? 1) /
        bien.nbProprietaires;

    if (bien.garage) {
      total +=
          (bien.surfaceGarage *
              (facteursEmission['Garage béton'] ?? 0) *
              reduction) /
          (dureesAmortissement['Garage béton'] ?? 1) /
          bien.nbProprietaires;
    }

    if (bien.piscine) {
      final surfacePiscine = bien.piscineLargeur * bien.piscineLongueur;
      total +=
          (surfacePiscine *
              (facteursEmission[bien.typePiscine] ?? 0) *
              reduction) /
          (dureesAmortissement[bien.typePiscine] ?? 1) /
          bien.nbProprietaires;
    }

    if (bien.abriEtSerre) {
      total +=
          (bien.surfaceAbriEtSerre *
              (facteursEmission['Abri de jardin bois'] ?? 0) *
              reduction) /
          (dureesAmortissement['Abri de jardin bois'] ?? 1) /
          bien.nbProprietaires;
    }

    return total;
  }

  Widget champNombre(
    String label,
    double value,
    void Function(double) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => setState(() => onChanged(value - 1)),
            ),
            Text(value.toStringAsFixed(0)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => onChanged(value + 1)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMsg != null)
      return Center(
        child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
      );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📊 Total : ${calculerTotalEmission().toStringAsFixed(2)} kgCO₂e/an",
                  ),
                  TextFormField(
                    initialValue: bien.nom,
                    decoration: const InputDecoration(
                      labelText: "Nom du logement",
                    ),
                    onChanged: (val) => setState(() => bien.nom = val),
                  ),
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
                  champNombre(
                    "Surface (m²)",
                    bien.surface,
                    (v) => bien.surface = v,
                  ),
                  champNombre(
                    "Année construction",
                    bien.anneeConstruction.toDouble(),
                    (v) => bien.anneeConstruction = v.toInt(),
                  ),
                  champNombre(
                    "Nb. propriétaires",
                    bien.nbProprietaires.toDouble(),
                    (v) => bien.nbProprietaires = v.toInt(),
                  ),
                ],
              ),
            ),
            CustomCard(
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text("J’ai un garage"),
                    value: bien.garage,
                    onChanged: (val) => setState(() => bien.garage = val!),
                  ),
                  if (bien.garage)
                    champNombre(
                      "Surface garage",
                      bien.surfaceGarage,
                      (v) => bien.surfaceGarage = v,
                    ),
                ],
              ),
            ),
            CustomCard(
              child: Column(
                children: [
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
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => bien.typePiscine = val!),
                    ),
                    champNombre(
                      "Longueur",
                      bien.piscineLongueur,
                      (v) => bien.piscineLongueur = v,
                    ),
                    champNombre(
                      "Largeur",
                      bien.piscineLargeur,
                      (v) => bien.piscineLargeur = v,
                    ),
                  ],
                ],
              ),
            ),
            CustomCard(
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text("J’ai un abri ou une serre"),
                    value: bien.abriEtSerre,
                    onChanged: (val) => setState(() => bien.abriEtSerre = val!),
                  ),
                  if (bien.abriEtSerre)
                    champNombre(
                      "Surface abri/serre",
                      bien.surfaceAbriEtSerre,
                      (v) => bien.surfaceAbriEtSerre = v,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: widget.onSave,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
