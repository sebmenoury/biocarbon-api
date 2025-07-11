import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import 'bien_immobilier.dart';
import '../../../ui/widgets/custom_dropdown_compact.dart';
import '../eqt_bien_immobilier/poste_bien_immobilier.dart';
import '../../../data/services/api_service.dart';
import 'bien_list_screen.dart';

class BienDeclarationScreen extends StatefulWidget {
  final BienImmobilier? bienExistant;
  final String? typeBienInitial;

  const BienDeclarationScreen({Key? key, this.bienExistant, this.typeBienInitial}) : super(key: key);

  @override
  State<BienDeclarationScreen> createState() => _BienDeclarationScreenState();
}

class _BienDeclarationScreenState extends State<BienDeclarationScreen> {
  String typeBien = 'Logement principal';
  String denomination = '';
  String adresse = '';
  bool inclureDansBilan = true;
  int nbProprietaires = 1;
  double nbHabitants = 1.0;
  late BienImmobilier bien;
  bool showSuccessMessage = false;

  void incrementProprietaires() {
    setState(() {
      nbProprietaires++;
    });
  }

  void decrementProprietaires() {
    setState(() {
      if (nbProprietaires > 1) nbProprietaires--;
    });
  }

  void incrementHabitants() {
    setState(() {
      nbHabitants += 0.25;
    });
  }

  void decrementHabitants() {
    setState(() {
      if (nbHabitants > 0.25) nbHabitants -= 0.25;
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.bienExistant != null) {
      bien = widget.bienExistant!;
      typeBien = bien.typeBien;
      denomination = bien.nomLogement;
      adresse = bien.adresse ?? '';
      inclureDansBilan = bien.inclureDansBilan ?? true;
      nbProprietaires = bien.nbProprietaires ?? 1;
      nbHabitants = bien.nbHabitants ?? 1.0;
    } else {
      typeBien = widget.typeBienInitial ?? 'Logement principal';
      inclureDansBilan = true;
      bien = BienImmobilier(
        idBien: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
        typeBien: typeBien,
        nomLogement: denomination,
        adresse: adresse,
        inclureDansBilan: inclureDansBilan,
        poste: PosteBienImmobilier(),
        nbProprietaires: nbProprietaires,
        nbHabitants: nbHabitants, // Initialisation de nbHabitants
      );
    }
  }

  void enregistrerBien() async {
    try {
      final nbHabitantsFormate = NumberFormat("0.##", "en_US").format(bien.nbHabitants);
      final result = await ApiService.addBien(
        idBien: bien.idBien!,
        codeIndividu: 'BASILE',
        typeBien: bien.typeBien,
        description: bien.nomLogement,
        adresse: bien.adresse ?? '',
        nbProprietaires: bien.nbProprietaires,
        nbHabitants: nbHabitantsFormate, // 👈 ici, en string bien formatée
        inclureDansBilan: bien.inclureDansBilan ? 'TRUE' : 'FALSE',
      );

      // print('✅ Bien enregistré : $result');
      // Affiche le message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Enregistrement effectué')));

      // Attend un peu puis retourne à la liste avec mise à jour
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BienListScreen()));
      });
    } catch (e) {
      // print('❌ Erreur enregistrement : $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'enregistrement du bien')));
    }
  }

  void updateBien() async {
    try {
      final data = bien.toMap('BASILE');
      data['Nb_Habitants'] = NumberFormat("0.##", "en_US").format(bien.nbHabitants); // 👈 ici
      final result = await ApiService.updateBien(bien.idBien!, data);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Mise à jour effectuée')));

      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BienListScreen()));
      });
    } catch (e) {
      // print('❌ Erreur mise à jour : $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour du bien')));
    }
  }

  void supprimerBien() async {
    // ⛔️ Empêche la suppression si c'est un logement principal
    if (bien.typeBien == 'Logement principal') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Vous ne pouvez pas supprimer le logement principal, vous pouvez uniquement le modifier.')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Confirmer la suppression", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            content: const Text("Souhaitez-vous vraiment supprimer ce bien (toutes les données associées seront supprimées) ?", style: TextStyle(fontSize: 11)),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler", style: TextStyle(fontSize: 11))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(fontSize: 11))),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteBien(bien.idBien!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Bien supprimé")));
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BienListScreen()));
        });
      } catch (e) {
        // print('❌ Erreur suppression : $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la suppression")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Stack(
        alignment: Alignment.center,
        children: [
          const Center(child: Text("Type et propriété du logement", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              iconSize: 18,
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BienListScreen()));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "⚙️ Le nombre de propriétaires correspond au nombre de financeurs du bien ou de la location, "
            "et est utilisé pour répartir par individu propriétaire l'énergie grise des équipements associés à ces biens.\n\n"
            "⚙️ Le nombre d'habitants correspond au nombre de personnes qui y vivent, et est utilisé pour répartir l'énergie d'usage des équipements associés à ces biens.",
            style: const TextStyle(fontSize: 11, height: 1.4),
            textAlign: TextAlign.justify,
          ),
        ),

        const SizedBox(height: 12),

        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choix du type de logement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CustomDropdownCompact(
                    value: typeBien,
                    items: const ['Logement principal', 'Logement secondaire'],
                    label: "Type de logement",
                    onChanged: (val) {
                      setState(() {
                        typeBien = val ?? 'Logement principal';
                        bien.typeBien = typeBien;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Carte 2 : Dénomination et Adresse
        CustomCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Identitié du logement', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6), // ← décalage ici
                      child: Text("Dénomination", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: bien.nomLogement,
                      onChanged: (val) => setState(() => bien.nomLogement = val),
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.only(bottom: 6), border: UnderlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6), // ← décalage ici
                      child: Text("Adresse", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: bien.adresse ?? '',
                      onChanged: (val) => setState(() => bien.adresse = val),
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.only(bottom: 6), border: UnderlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),

        CustomCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nombre de personnes associées au logement', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(padding: EdgeInsets.only(left: 6), child: Text("Nombre de propriétaires", style: TextStyle(fontSize: 11))),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.remove), onPressed: decrementProprietaires, visualDensity: VisualDensity.compact, iconSize: 20),
                      Text("$nbProprietaires", style: const TextStyle(fontSize: 11)),
                      IconButton(icon: const Icon(Icons.add), onPressed: incrementProprietaires, visualDensity: VisualDensity.compact, iconSize: 20),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(padding: EdgeInsets.only(left: 6), child: Text("Nombre d'habitants", style: TextStyle(fontSize: 11))),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.remove), onPressed: decrementHabitants, visualDensity: VisualDensity.compact, iconSize: 20),
                      Text(nbHabitants.toStringAsFixed(2), style: const TextStyle(fontSize: 11)),
                      IconButton(icon: const Icon(Icons.add), onPressed: incrementHabitants, visualDensity: VisualDensity.compact, iconSize: 20),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Carte 3 : Inclure dans le bilan
        CustomCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Inclure ce logement dans le bilan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Transform.scale(
                scale: 0.85,
                child: Checkbox(value: bien.inclureDansBilan == true, visualDensity: VisualDensity.compact, onChanged: (v) => setState(() => bien.inclureDansBilan = v ?? true)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                if (bien.nomLogement.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Merci de saisir une dénomination')));
                  return;
                }

                bien.nbProprietaires = nbProprietaires;
                bien.nbHabitants = nbHabitants;

                if (widget.bienExistant != null) {
                  updateBien();
                } else {
                  enregistrerBien();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
              child: const Text("Enregistrer", style: TextStyle(color: Colors.black)),
            ),
            OutlinedButton(
              onPressed: widget.bienExistant != null ? supprimerBien : null,
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.teal.shade200)),
              child: const Text("Supprimer la déclaration", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}
