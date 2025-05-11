import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
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

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Mes logements',
      actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: ajouterNouveauBien),
      ],
      child:
          biens.isEmpty
              ? const Center(child: Text("Aucun logement déclaré"))
              : ListView.builder(
                itemCount: biens.length,
                itemBuilder: (context, index) {
                  final bien = biens[index];
                  return CustomCard(
                    onTap: () => modifierBien(bien),
                    child: ListTile(
                      leading: const Icon(Icons.home),
                      title: Text(
                        bien.nom.isEmpty ? 'Logement sans nom' : bien.nom,
                      ),
                      subtitle: Text(
                        "${bien.type}, ${bien.surface.toInt()} m²",
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
    );
  }
}
