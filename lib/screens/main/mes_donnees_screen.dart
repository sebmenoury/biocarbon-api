import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../core/constants/app_icons.dart';
import '../declaration/poste_list_screen.dart';
import '../declaration/ref_type_category.dart';
import '../declaration/bien_immobilier/bien_list_screen.dart';

class MesDonneesScreen extends StatefulWidget {
  final int initialTabIndex;
  const MesDonneesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MesDonneesScreen> createState() => _MesDonneesScreenState();
}

class _MesDonneesScreenState extends State<MesDonneesScreen> {
  late int selectedIndex;

  final List<String> equipementLabels = [
    'Biens Immobiliers',
    'Construction',
    'Rénovation',
    'Equipements Confort',
    'Equipements Ménager',
    'Equipements Bricolage',
    'Equipements Multi-media',
    'Véhicules',
  ];

  final List<String> usageLabels = [
    'Electricité',
    'Gaz et Fioul',
    'Déchets et Eau',
    'Alimentation',
    'Loisirs',
    'Habillement',
    'Banques et Assurances',
    'Déplacements Avion',
    'Déplacements Voiture',
    'Déplacements Train/Métro/Bus',
    'Déplacements Autres',
    'Services publics',
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final currentLabels = selectedIndex == 0 ? equipementLabels : usageLabels;

    return BaseScreen(
      title: const Text("Mes données", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      children: [
        // Onglets Equipements / Usages
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(color: selectedIndex == 0 ? Colors.indigo : Colors.grey.shade200, borderRadius: const BorderRadius.horizontal(left: Radius.circular(20))),
                    alignment: Alignment.center,
                    child: Text("Equipements", style: TextStyle(fontSize: 12, color: selectedIndex == 0 ? Colors.white : Colors.black)),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(color: selectedIndex == 1 ? Colors.indigo : Colors.grey.shade200, borderRadius: const BorderRadius.horizontal(right: Radius.circular(20))),
                    alignment: Alignment.center,
                    child: Text("Usages", style: TextStyle(fontSize: 12, color: selectedIndex == 1 ? Colors.white : Colors.black)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            selectedIndex == 0
                ? "⚙️ Calcul de l'empreinte des équipements : correspond à l’amortissement annuel de l’énergie grise de construction sur la durée théorique de vie de l’équipement, divisé par le nombre de propriétaires."
                : "⚙️ Calcul de l'empreinte des usages : correspond à la valeur d'émission associée à la consommation de cet usage sur une année, divisée par le nombre de propriétaires pour les usages liés au logement.",
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(height: 12),

        // Grille de sous-catégories
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.8),
          itemCount: currentLabels.length,
          itemBuilder: (context, index) {
            final label = currentLabels[index];
            final typeCategorie = getTypeCategorieFromLabel(label)!;
            final icon = sousCategorieIcons[label] ?? Icons.help_outline;
            final color = souscategoryColors[label] ?? Colors.grey;

            return CustomCard(
              padding: const EdgeInsets.all(8),
              onTap: () {
                if (label == 'Biens Immobiliers') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BienListScreen()));
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PosteListScreen(typeCategorie: typeCategorie, sousCategorie: label, codeIndividu: 'BASILE', valeurTemps: '2025')));
                }
              },
              backgroundColor: color.withOpacity(0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(icon, size: 22, color: color), const SizedBox(height: 4), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))],
              ),
            );
          },
        ),
      ],
    );
  }
}
