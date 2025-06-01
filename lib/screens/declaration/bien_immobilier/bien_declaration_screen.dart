import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import 'bien_immobilier.dart';
import '../../../ui/widgets/custom_dropdown_compact.dart';
import '../eqt_bien_immobilier/poste_bien_immobilier.dart';
import '../../../data/services/api_service.dart';
import 'dart:convert';

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
  late BienImmobilier bien;

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

  @override
  void initState() {
    super.initState();

    if (widget.bienExistant != null) {
      bien = widget.bienExistant!;
      typeBien = bien.typeBien;
      denomination = bien.nomLogement;
      adresse = bien.adresse ?? '';
      inclureDansBilan = bien.inclureDansBilan ?? true; // 👈 valeur par défaut
      nbProprietaires = bien.nbProprietaires ?? 1;
    } else {
      typeBien = widget.typeBienInitial ?? 'Logement principal';
      inclureDansBilan = true; // 👈 valeur par défaut
      bien = BienImmobilier(
        idBien: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
        typeBien: typeBien,
        nomLogement: denomination,
        adresse: adresse,
        inclureDansBilan: inclureDansBilan,
        poste: PosteBienImmobilier(),
        nbProprietaires: nbProprietaires,
      );
    }
  }

  void enregistrerBien() async {
    // 🔍 Ajoute cette ligne AVANT l'appel à l'API
    print(
      jsonEncode({
        'ID_Bien': bien.idBien,
        'Code_Individu': 'BASILE',
        'Type_Bien': bien.typeBien,
        'Dénomination': bien.nomLogement,
        'Adresse': bien.adresse ?? '',
        'nbPriopriétaires': bien.nbProprietaires,
        'Inclure_dans_bilan': bien.inclureDansBilan ? 'TRUE' : 'FALSE',
      }),
    );
    try {
      final result = await ApiService.addBien(
        idBien: bien.idBien!,
        codeIndividu: 'BASILE', // ou dynamiquement
        typeBien: bien.typeBien,
        description: bien.nomLogement,
        adresse: bien.adresse ?? '',
        nbProprietaires: bien.nbProprietaires,
        inclureDansBilan: bien.inclureDansBilan ? 'TRUE' : 'FALSE',
      );

      print('✅ Bien enregistré : $result');
      Navigator.pop(context);
    } catch (e) {
      print('❌ Erreur enregistrement : $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'enregistrement du bien')));
    }
  }

  void updateBien() async {
    try {
      final data = bien.toMap('BASILE'); // au cas où tu veux tout envoyer
      final result = await ApiService.updateBien(bien.idBien!, data);

      print('🟠 Bien mis à jour : $result');
      Navigator.pop(context);
    } catch (e) {
      print('❌ Erreur mise à jour : $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour du bien')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text("Type et propriété du logement", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              iconSize: 18,
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      children: [
        CustomCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Type de bien
              CustomDropdownCompact(
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
              const SizedBox(height: 12),

              /// Dénomination
              Row(
                children: [
                  const Expanded(flex: 2, child: Text("Dénomination", style: TextStyle(fontSize: 11))),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: bien.nomLogement,
                      onChanged: (val) => setState(() => bien.nomLogement = val),
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 6),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// Adresse
              Row(
                children: [
                  const Expanded(flex: 2, child: Text("Adresse", style: TextStyle(fontSize: 11))),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: bien.adresse ?? '',
                      onChanged: (val) => setState(() => bien.adresse = val),
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 6),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// Inclure dans le bilan
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Checkbox(
                      value: ['TRUE', true].contains(bien.inclureDansBilan), // 👈 fallback si null
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setState(() => bien.inclureDansBilan = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text("Inclure dans le bilan", style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        /// Nombre de propriétaires
        CustomCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Nombre de propriétaires", style: TextStyle(fontSize: 11)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: decrementProprietaires,
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                      ),
                      Text("$nbProprietaires", style: const TextStyle(fontSize: 11)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: incrementProprietaires,
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        /// Bouton final
        Center(
          child: ElevatedButton(
            onPressed: () {
              bien.nbProprietaires = nbProprietaires;
              if (widget.bienExistant != null) {
                updateBien();
              } else {
                enregistrerBien();
              }
            },
            child: Text(
              widget.bienExistant != null ? "Mettre à jour" : "Enregistrer",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
