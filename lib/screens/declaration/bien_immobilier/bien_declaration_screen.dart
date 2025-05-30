import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import 'bien_immobilier.dart';
import '../../../ui/widgets/custom_dropdown_compact.dart';
import '../eqt_bien_immobilier/poste_bien_immobilier.dart';

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
      inclureDansBilan = bien.inclureDansBilan;
      nbProprietaires = bien.nbProprietaires;
    } else {
      typeBien = widget.typeBienInitial ?? 'Logement principal';
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

  void enregistrerBien() {
    // TODO: implémenter l'enregistrement réel
    print("✅ Enregistrer : ${bien.typeBien} - ${bien.nomLogement}");
  }

  void updateBien() {
    // TODO: implémenter la mise à jour réelle
    print("✏️ Mise à jour du bien : ${bien.idBien}");
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
                      style: const TextStyle(fontSize: 12),
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
                      value: bien.inclureDansBilan,
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
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
                      Text("$nbProprietaires", style: const TextStyle(fontSize: 12)),
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
            child: Text(widget.bienExistant != null ? "Mettre à jour" : "Enregistrer"),
          ),
        ),
      ],
    );
  }
}
