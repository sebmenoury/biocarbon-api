import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../data/services/api_service.dart';
import '../../data/logement/bien_immobilier.dart';
import '../../data/logement/emission_calculator_immobilier.dart';

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
  bool showGarage = false;
  bool showPiscine = false;
  bool showAbri = false;

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
      });
    } catch (e) {
      setState(() {
        errorMsg = "Erreur lors du chargement des équipements";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = calculerTotalEmission(
      bien,
      facteursEmission,
      dureesAmortissement,
    );

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMsg != null) {
      return Scaffold(
        body: Center(
          child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return BaseScreen(
      title: const Text(
        "Bien immobilier",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// HEADER
            CustomCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        sousCategorieIcons['Biens Immobiliers'] ?? Icons.home,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Bien immobilier",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    "${total.toStringAsFixed(0)} kgCO₂/an",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            /// IDENTITÉ DU BIEN
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: bien.type,
                    decoration: const InputDecoration(
                      labelText: "Type de bien",
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12),
                    items:
                        ["Maison", "Appartement", "Maison Passive"]
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => bien.type = val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: bien.nomLogement,
                    decoration: const InputDecoration(
                      labelText: "Dénomination du bien",
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (val) => bien.nomLogement = val,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: bien.adresse ?? '',
                    decoration: const InputDecoration(
                      labelText: "Adresse",
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (val) => bien.adresse = val,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: bien.inclureDansBilan ?? true,
                        onChanged:
                            (v) => setState(() => bien.inclureDansBilan = v),
                      ),
                      const Text(
                        "Inclure dans le bilan",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            /// DESCRIPTIF DU BIEN
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value:
                        bien.nomEquipement.isNotEmpty
                            ? bien.nomEquipement
                            : null,
                    decoration: const InputDecoration(
                      labelText: "Type de maison/appartement",
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12),
                    items:
                        facteursEmission.keys
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => bien.nomEquipement = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: bien.surface.toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: "Surface (m²)",
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    onChanged:
                        (val) => bien.surface = double.tryParse(val) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: bien.anneeConstruction.toString(),
                    decoration: const InputDecoration(
                      labelText: "Année de construction",
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    onChanged:
                        (val) =>
                            bien.anneeConstruction = int.tryParse(val) ?? 2000,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Nombre de propriétaires",
                        style: TextStyle(fontSize: 12),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed:
                                () => setState(() => bien.nbProprietaires--),
                          ),
                          Text(
                            bien.nbProprietaires.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed:
                                () => setState(() => bien.nbProprietaires++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            /// GARAGE
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Déclarer un garage",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      showGarage ? Icons.expand_less : Icons.chevron_right,
                    ),
                    onTap: () => setState(() => showGarage = !showGarage),
                  ),
                  if (showGarage)
                    TextFormField(
                      initialValue: bien.surfaceGarage.toStringAsFixed(0),
                      decoration: const InputDecoration(
                        labelText: "Surface garage (m²)",
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 12),
                      keyboardType: TextInputType.number,
                      onChanged:
                          (val) =>
                              bien.surfaceGarage = double.tryParse(val) ?? 0,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            /// PISCINE
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Déclarer une piscine",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      showPiscine ? Icons.expand_less : Icons.chevron_right,
                    ),
                    onTap: () => setState(() => showPiscine = !showPiscine),
                  ),
                  if (showPiscine)
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: bien.typePiscine,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 12),
                          items:
                              ["Piscine béton", "Piscine coque"]
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => bien.typePiscine = val!),
                        ),
                        TextFormField(
                          initialValue: bien.piscineLongueur.toString(),
                          decoration: const InputDecoration(
                            labelText: "Longueur (m)",
                            labelStyle: TextStyle(fontSize: 12),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged:
                              (val) =>
                                  bien.piscineLongueur =
                                      double.tryParse(val) ?? 0,
                        ),
                        TextFormField(
                          initialValue: bien.piscineLargeur.toString(),
                          decoration: const InputDecoration(
                            labelText: "Largeur (m)",
                            labelStyle: TextStyle(fontSize: 12),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged:
                              (val) =>
                                  bien.piscineLargeur =
                                      double.tryParse(val) ?? 0,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            /// ABRI / SERRE
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Déclarer abri / serre",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      showAbri ? Icons.expand_less : Icons.chevron_right,
                    ),
                    onTap: () => setState(() => showAbri = !showAbri),
                  ),
                  if (showAbri)
                    TextFormField(
                      initialValue: bien.surfaceAbriEtSerre.toStringAsFixed(0),
                      decoration: const InputDecoration(
                        labelText: "Surface abri / serre (m²)",
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 12),
                      keyboardType: TextInputType.number,
                      onChanged:
                          (val) =>
                              bien.surfaceAbriEtSerre =
                                  double.tryParse(val) ?? 0,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            /// BOUTON
            ElevatedButton.icon(
              onPressed: () async {
                final double emission = calculerTotalEmission(
                  bien,
                  facteursEmission,
                  dureesAmortissement,
                );
                await ApiService.savePoste({
                  "Code_Individu": "BASILE",
                  "Type_Temps": "Réel",
                  "Valeur_Temps": "2025",
                  "Date_enregistrement": DateTime.now().toIso8601String(),
                  "Type_Poste": "Equipement",
                  "Type_Categorie": "Logement",
                  "Sous_Categorie": "Habitat",
                  "Nom_Poste": bien.nomEquipement,
                  "Nom_Logement": bien.nomLogement,
                  "Quantite": bien.surface,
                  "Unite": "m²",
                  "Facteur_Emission": facteursEmission[bien.type],
                  "Emission_Calculee": emission,
                  "Mode_Calcul": "Amorti",
                  "Annee_Achat": bien.anneeConstruction,
                  "Duree_Amortissement": dureesAmortissement[bien.type],
                });

                if (widget.onSave != null) widget.onSave!();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
