import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/post_list_card.dart'
import 'construction_screen.dart';

class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() => _LogementListScreenState();
}

class _LogementListScreenState extends State<LogementListScreen> {
  final List<BienImmobilier> biens = [];

  void ajouterNouveauBien() {
    final nouveauBien = BienImmobilier(
      id: UniqueKey().toString(),
      nom: '',
      type: 'Maison Classique',
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => ConstructionScreen(
              bien: nouveauBien,
              onSave: () {
                setState(() => biens.add(nouveauBien));
                Navigator.of(context).pop();
              },
            ),
      ),
    );
  }

  void modifierBien(BienImmobilier bien) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => ConstructionScreen(
              bien: bien,
              onSave: () {
                setState(() {});
                Navigator.of(context).pop();
              },
            ),
      ),
    );
  }

  Widget build(BuildContext context) {
  return BaseScreen(
    title: 'Mes logements',
    actions: [
      IconButton(icon: const Icon(Icons.add), onPressed: ajouterNouveauBien),
    ],
    child: biens.isEmpty
        ? CustomCard(
            margin: const EdgeInsets.all(16),
            onTap: ajouterNouveauBien,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline),
                SizedBox(width: 8),
                Text("Déclarer un nouveau logement"),
              ],
            ),
          )
        : ListView.builder(
            itemCount: biens.length,
            itemBuilder: (context, index) {
              final bien = biens[index];
              final type = bien.type.toLowerCase();
              final icon = type.contains('appartement') ? Icons.apartment : Icons.home;

              return PostListCard(
                icon: icon,
                title: bien.nom.isEmpty ? 'Logement sans nom' : bien.nom,
                subtitle: "${bien.type}, ${bien.surface.toInt()} m²",
                emission: "${bien.calculerTotalEmission().toStringAsFixed(2)} kgCO₂e/an",
                onEdit: () => modifierBien(bien),
                onDelete: () => setState(() => biens.removeAt(index)),
              );
            },
          ),
  );
}

