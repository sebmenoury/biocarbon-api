import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../../../data/classes/poste_vehicule.dart';
import 'emission_calculator_vehicules.dart';

class VehiculeScreen extends StatefulWidget {
  final String codeIndividu;
  final String idBien;

  const VehiculeScreen({super.key, required this.codeIndividu, required this.idBien});

  @override
  State<VehiculeScreen> createState() => _VehiculeScreenState();
}

class _VehiculeScreenState extends State<VehiculeScreen> {
  Map<String, List<PosteVehicule>> vehiculesParCategorie = {'Voitures': [], '2-roues': [], 'Autres': []};
  bool isLoading = true;
  double totalEmission = 0;
  String? idBienSelectionne;
  String? typeBienSelectionne;
  int nbProprietaires = 1;

  @override
  void initState() {
    super.initState();
    loadData(widget.codeIndividu, widget.idBien);
  }

  bool hasPostesExistants = false;
  Future<void> loadData(String codeIndividu, String idBien) async {
    // Chargement du bien sélectionné pour récupérer les bons paramètres
    final bien = await ApiService.getBienParId(codeIndividu, idBien);

    final idBienSelectionne = bien['ID_Bien']?.toString() ?? '';
    final typeBienSelectionne = bien['Type_Bien']?.toString() ?? '';
    final denominationSelectionne = bien['Dénomination']?.toString() ?? '';
    final nbProprietaires = int.tryParse(bien['Nb_Proprietaires']?.toString() ?? '') ?? 1;

    final ref = await ApiService.getRefEquipements();

    // 🔁 Appel par ID_Bien + filtre sur la sous-catégorie
    final tousLesPostes = await ApiService.getPostesParIdBien(idBienSelectionne);
    final postesExistants = tousLesPostes.where((p) => p.sousCategorie == "Véhicules").toList();

    final Map<String, List<PosteVehicule>> result = {'Voitures': [], '2-roues': [], 'Autres': []};

    final baseEquipements = ref.where((eq) => eq['Type_Categorie'] == 'Déplacements' && eq['Sous_Categorie'] == 'Véhicules');

    final nomsPostesExistants = postesExistants.map((p) => p.nomPoste).toSet();

    // Ajout des équipements de référence sauf ceux déjà déclarés
    for (final eq in baseEquipements) {
      final nom = eq['Nom_Equipement'];
      if (nomsPostesExistants.contains(nom)) continue;

      final facteur = double.tryParse(eq['Valeur_Emission_Grise']?.toString() ?? '') ?? 0;
      final duree = int.tryParse(eq['Duree_Amortissement']?.toString() ?? '') ?? 1;

      final categorie =
          nom.toLowerCase().startsWith('voitures')
              ? 'Voitures'
              : nom.toLowerCase().startsWith('2-roues')
              ? '2-roues'
              : 'Autres';

      result[categorie]!.add(
        PosteVehicule(
          nomEquipement: nom,
          anneeAchat: DateTime.now().year,
          facteurEmission: facteur,
          dureeAmortissement: duree,
          quantite: 0,
          idBien: idBienSelectionne,
          typeBien: typeBienSelectionne,
          nomLogement: denominationSelectionne,
          nbProprietaires: nbProprietaires,
        ),
      );
    }

    // Ajout des postes existants avec données utilisateur
    for (final p in postesExistants) {
      final eqMatching = ref.firstWhere((e) => e['Nom_Equipement'] == p.nomPoste, orElse: () => <String, dynamic>{});

      final facteur = double.tryParse(eqMatching['Valeur_Emission_Grise']?.toString() ?? '') ?? 0;
      final duree = int.tryParse(eqMatching['Duree_Amortissement']?.toString() ?? '') ?? 1;

      final groupe =
          (p.nomPoste ?? '').toLowerCase().startsWith('voitures')
              ? 'Voitures'
              : (p.nomPoste ?? '').toLowerCase().startsWith('2-roues')
              ? '2-roues'
              : 'Autres';

      print('Poste: ${p.nomPoste} | idusageinitial = ${p.idUsage} | q=${p.quantite} | ');

      result[groupe]!.add(
        PosteVehicule(
          nomEquipement: p.nomPoste ?? '',
          anneeAchat: p.anneeAchat ?? DateTime.now().year,
          facteurEmission: facteur,
          dureeAmortissement: duree,
          quantite: 1,
          idBien: p.idBien,
          typeBien: p.typeBien,
          nomLogement: denominationSelectionne,
          nbProprietaires: nbProprietaires,
          idUsageInitial: p.idUsage, // ✅ conserve la clé d’origine
        ),
      );
    }

    setState(() {
      // Trie les postes par quantité décroissante dans chaque groupe
      for (final groupe in result.keys) {
        result[groupe]!.sort((a, b) => b.quantite.compareTo(a.quantite));
      }
      vehiculesParCategorie = result;
      hasPostesExistants = postesExistants.isNotEmpty; // ✅ ligne clé

      recalculerTotal();
      isLoading = false;
    });
  }

  void recalculerTotal() {
    totalEmission = vehiculesParCategorie.values.expand((v) => v).fold(0.0, (sum, p) => sum + calculerTotalEmissionVehicule(p));
    print('Total recalculé : $totalEmission kgCO₂');
  }

  Future<void> enregistrerOuMettreAJour() async {
    for (final categorie in vehiculesParCategorie.values) {
      for (final poste in categorie) {
        if (poste.quantite > 0) {
          // ✅ on ignore les postes à 0
          final emission = calculerTotalEmissionVehicule(poste);
          final idUsage = poste.idUsageInitial ?? "${poste.idBien}_Véhicules_${poste.nomEquipement}_${poste.anneeAchat}".replaceAll(' ', '_');

          await ApiService.saveOrUpdatePoste({
            "ID_Usage": idUsage,
            "Code_Individu": "BASILE", // à remplacer par widget.codeIndividu si besoin
            "Type_Temps": "Réel",
            "Valeur_Temps": "2025", // idem ici
            "Date_enregistrement": DateTime.now().toIso8601String(),
            "ID_Bien": poste.idBien,
            "Type_Bien": poste.typeBien,
            "Type_Poste": "Equipement",
            "Type_Categorie": "Déplacements",
            "Sous_Categorie": "Véhicules",
            "Nom_Poste": poste.nomEquipement,
            "Nom_Logement": poste.nomLogement,
            "Quantite": poste.quantite, // ✅ on respecte la valeur réelle
            "Unite": "unité",
            "Frequence": "",
            "Facteur_Emission": poste.facteurEmission,
            "Emission_Calculee": emission,
            "Mode_Calcul": "Amorti",
            "Annee_Achat": poste.anneeAchat,
            "Duree_Amortissement": poste.dureeAmortissement,
          });
        }
      }
    }
  }

  Future<void> supprimerPoste() async {
    final postes = await ApiService.getPostesBysousCategorie(
      "Véhicules",
      widget.codeIndividu,
      "2025", // ou widget.valeurTemps si dispo
    );

    final postesPourCeBien = postes.where((p) => p.idBien == widget.idBien).toList();

    for (final poste in postesPourCeBien) {
      await ApiService.deleteUCPoste(poste.idUsage);
    }

    setState(() {
      hasPostesExistants = false;
      vehiculesParCategorie.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Déclaration supprimée")));
  }

  Widget buildVehiculeLine(PosteVehicule poste, String categorie, int index) {
    final isActive = poste.quantite > 0;
    final colorBloc = isActive ? Colors.white : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(poste.nomEquipement.replaceFirst(RegExp(r'^(Voitures|2-roues|Autres)\s*-\s*'), ''), style: const TextStyle(fontSize: 12))),
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
                        final doublons = vehiculesParCategorie[categorie]!.where((p) => p.nomEquipement == poste.nomEquipement).toList();
                        if (doublons.length > 1) {
                          vehiculesParCategorie[categorie]!.removeAt(index);
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
                      final doublons = vehiculesParCategorie[categorie]!.where((p) => p.nomEquipement == poste.nomEquipement).toList();
                      if (poste.quantite == 0) {
                        poste.quantite = 1;
                      } else {
                        vehiculesParCategorie[categorie]!.insert(index + 1, PosteVehicule.clone(poste));
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

  Widget buildCategorieCard(String titre, List<PosteVehicule> vehicules) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: const [
                  SizedBox(width: 70, child: Text("Quantité", style: TextStyle(fontSize: 10, color: Colors.grey))),
                  SizedBox(width: 12),
                  SizedBox(width: 100, child: Text("Année(s) d'achat", style: TextStyle(fontSize: 10, color: Colors.grey))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...vehicules.asMap().entries.map((entry) => buildVehiculeLine(entry.value, titre, entry.key)).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return BaseScreen(
      title: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          const Center(child: Text("Déclaration des Véhicules", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
      children: [
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Empreinte d'amortissement annuel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text("${totalEmission.toStringAsFixed(0)} kgCO₂", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...['Voitures', '2-roues', 'Autres'].map((groupe) {
          final items = vehiculesParCategorie[groupe] ?? [];
          for (var i = 0; i < items.length; i++) {
            final p = items[i];
          }

          if (items.isNotEmpty) return buildCategorieCard(groupe, items);
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 12),
        (hasPostesExistants)
            ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: supprimerPoste,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    minimumSize: const Size(120, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Supprimer", style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton.icon(
                  onPressed: enregistrerOuMettreAJour,
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
            : Center(
              child: ElevatedButton.icon(
                onPressed: enregistrerOuMettreAJour,
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
