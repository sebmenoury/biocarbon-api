import 'package:flutter/material.dart';
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
        final facteur = double.tryParse(e['Valeur_Emission_Grise'].toString().replaceAll(',', '.')) ?? 0;
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

  Widget champNombre(String label, double value, void Function(double) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => onChanged(value - 1))),
            Text(value.toStringAsFixed(0)),
            IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => onChanged(value + 1))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMsg != null) {
      return Center(child: Text(errorMsg!, style: const TextStyle(color: Colors.red)));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📊 Total : ${calculerTotalEmission(bien, facteursEmission, dureesAmortissement).toStringAsFixed(2)} kgCO₂e/an"),
                  TextFormField(
                    initialValue: bien.nomLogement,
                    decoration: const InputDecoration(labelText: "Nom du logement"),
                    onChanged: (val) => setState(() => bien.nomLogement = val),
                  ),
                  DropdownButton<String>(
                    value: facteursEmission.keys.contains(bien.type) ? bien.type : null,
                    isExpanded: true,
                    items:
                        facteursEmission.keys
                            .where((k) => k.contains("Maison") || k.contains("Appartement"))
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        bien.nomEquipement = val!;
                        bien.type = val;
                      });
                    },
                  ),
                  champNombre("Surface (m²)", bien.surface, (v) => bien.surface = v),
                  champNombre("Année construction", bien.anneeConstruction.toDouble(), (v) => bien.anneeConstruction = v.toInt()),
                  champNombre("Nb. propriétaires", bien.nbProprietaires.toDouble(), (v) => bien.nbProprietaires = v.toInt()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: InkWell(
                onTap: () => setState(() => bien.garage = !bien.garage),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text("Déclarer un garage", style: TextStyle(fontSize: 13)), const Icon(Icons.chevron_right, size: 18)],
                ),
              ),
            ),
            if (bien.garage) CustomCard(child: champNombre("Surface garage", bien.surfaceGarage, (v) => bien.surfaceGarage = v)),
            const SizedBox(height: 12),
            CustomCard(
              child: InkWell(
                onTap: () => setState(() => bien.piscine = !bien.piscine),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text("Déclarer une piscine", style: TextStyle(fontSize: 13)), const Icon(Icons.chevron_right, size: 18)],
                ),
              ),
            ),
            if (bien.piscine)
              CustomCard(
                child: Column(
                  children: [
                    DropdownButton<String>(
                      value: bien.typePiscine,
                      isExpanded: true,
                      items: ["Piscine béton", "Piscine coque"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => bien.typePiscine = val!),
                    ),
                    champNombre("Longueur", bien.piscineLongueur, (v) => bien.piscineLongueur = v),
                    champNombre("Largeur", bien.piscineLargeur, (v) => bien.piscineLargeur = v),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            CustomCard(
              child: InkWell(
                onTap: () => setState(() => bien.abriEtSerre = !bien.abriEtSerre),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text("Déclarer abri / serre", style: TextStyle(fontSize: 13)), const Icon(Icons.chevron_right, size: 18)],
                ),
              ),
            ),
            if (bien.abriEtSerre) CustomCard(child: champNombre("Surface abri/serre", bien.surfaceAbriEtSerre, (v) => bien.surfaceAbriEtSerre = v)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final double emission = calculerTotalEmission(bien, facteursEmission, dureesAmortissement);

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
            ),
          ],
        ),
      ),
    );
  }
}
