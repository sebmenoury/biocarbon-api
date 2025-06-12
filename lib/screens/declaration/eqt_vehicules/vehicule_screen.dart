import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import '../../../data/classes/poste_vehicule.dart';
import 'emission_calculator_vehicules.dart';

class VehiculeScreen extends StatefulWidget {
  const VehiculeScreen({super.key});

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
    loadData();
  }

  bool hasPostesExistants = false;

  Future<void> loadData() async {
    final ref = await ApiService.getRefEquipements();
    final postesExistants = await ApiService.getPostesBysousCategorie("Véhicules", "BASILE", "2025");
    final bien = await ApiService.getBienActif();
    hasPostesExistants = postesExistants.isNotEmpty;

    idBienSelectionne = bien['ID_Bien'];
    typeBienSelectionne = bien['Type_Bien'];
    nbProprietaires = bien['Nb_Proprietaires'] ?? 1;

    final Map<String, List<PosteVehicule>> result = {'Voitures': [], '2-roues': [], 'Autres': []};

    for (final eq in ref) {
      if (eq['Type_Categorie'] == 'Déplacements' && eq['Sous_Categorie'] == 'Véhicules') {
        final nom = eq['Nom_Equipement'].toString();
        final facteur = double.tryParse(eq['Valeur_Emission_Grise'].toString()) ?? 0;
        final duree = int.tryParse(eq['Duree_Amortissement'].toString()) ?? 1;

        final nomLower = nom.toLowerCase();
        String categorie;
        if (nomLower.startsWith('voitures')) {
          categorie = 'Voitures';
        } else if (nomLower.startsWith('2-roues')) {
          categorie = '2-roues';
        } else {
          categorie = 'Autres';
        }

        final existantsPourCeNom = postesExistants.where((p) => p.nomPoste == nom);

        if (existantsPourCeNom.isNotEmpty) {
          for (final poste in existantsPourCeNom) {
            result[categorie]!.add(
              PosteVehicule(
                nomEquipement: nom,
                anneeAchat: poste.anneeAchat ?? DateTime.now().year,
                facteurEmission: facteur,
                dureeAmortissement: duree,
                nbProprietaires: nbProprietaires, // 👈 valeur du bien
                idBien: poste.idBien ?? idBienSelectionne,
                typeBien: poste.typeBien ?? typeBienSelectionne,
              ),
            );
          }
        } else {
          result[categorie]!.add(
            PosteVehicule(
              nomEquipement: nom,
              anneeAchat: DateTime.now().year,
              facteurEmission: facteur,
              dureeAmortissement: duree,
              nbProprietaires: nbProprietaires,
              idBien: idBienSelectionne,
              typeBien: typeBienSelectionne,
            ),
          );
        }
      }
    }

    setState(() {
      vehiculesParCategorie = result;
      recalculerTotal();
      isLoading = false;
    });
  }

  void recalculerTotal() {
    totalEmission = vehiculesParCategorie.values.expand((v) => v).fold(0.0, (sum, p) => sum + calculerTotalEmissionVehicule(p));
  }

  Future<void> saveData() async {
    for (final categorie in vehiculesParCategorie.values) {
      for (final poste in categorie) {
        final emission = calculerTotalEmissionVehicule(poste);
        await ApiService.saveOrUpdatePoste({
          "Code_Individu": "BASILE",
          "Type_Temps": "Réel",
          "Valeur_Temps": "2025",
          "Date_enregistrement": DateTime.now().toIso8601String(),
          "ID_Bien": idBienSelectionne,
          "Type_Bien": typeBienSelectionne,
          "Type_Poste": "Equipement",
          "Type_Categorie": "Déplacements",
          "Sous_Categorie": "Véhicules",
          "Nom_Poste": poste.nomEquipement,
          "Quantite": 1,
          "Unite": "unité",
          "Facteur_Emission": poste.facteurEmission,
          "Emission_Calculee": emission,
          "Mode_Calcul": "Amorti",
          "Annee_Achat": poste.anneeAchat,
          "Duree_Amortissement": poste.dureeAmortissement,
          "Nb_Proprietaires": poste.nbProprietaires,
        });
      }
    }
    Navigator.pop(context);
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Padding(padding: EdgeInsets.only(right: 40), child: Text("Quantité", style: TextStyle(fontSize: 11, color: Colors.grey))),
              const Padding(padding: EdgeInsets.only(right: 10), child: Text("Année(s) d'achat", style: TextStyle(fontSize: 11, color: Colors.grey))),
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
          print('>>> Groupe $groupe : ${items.length} éléments');
          for (var i = 0; i < items.length; i++) {
            final p = items[i];
            print('  - ${p.nomEquipement} | quantité: ${p.quantite} | année: ${p.anneeAchat}');
          }

          if (items.isNotEmpty) return buildCategorieCard(groupe, items);
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: saveData,
              icon: Icon(hasPostesExistants ? Icons.update : Icons.save, size: 14),
              label: Text(hasPostesExistants ? "Mettre à jour" : "Enregistrer", style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
