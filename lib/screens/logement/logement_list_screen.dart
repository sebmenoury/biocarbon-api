import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../data/services/api_service.dart';

class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() => _LogementListScreenState();
}

class _LogementListScreenState extends State<LogementListScreen> {
  List<Map<String, dynamic>> logements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPostesLogement();
  }

  Future<void> loadPostesLogement() async {
    try {
      final data = await ApiService.getUCPostes("BASILE", "2025");
      final result =
          data
              .where(
                (e) =>
                    e['Type_Categorie'] == 'Logement' &&
                    e['Sous_Categorie'] == 'Habitat' &&
                    e['Type_Poste'] == 'Equipement',
              )
              .toList();

      setState(() {
        logements = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error visually if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Mes logements',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            // Ajout logement temporaire (à remplacer par ouverture formulaire)
          },
        ),
      ],
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : logements.isEmpty
              ? CustomCard(
                margin: const EdgeInsets.all(16),
                onTap: () {
                  // Ajout d’un nouveau logement
                },
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
                itemCount: logements.length,
                itemBuilder: (context, index) {
                  final log = logements[index];
                  final icon =
                      log["Nom_Poste"].toString().toLowerCase().contains(
                            "appartement",
                          )
                          ? Icons.apartment
                          : Icons.home;

                  return PostListCard(
                    icon: icon,
                    title: log["Nom_Poste"] ?? "Logement",
                    subtitle: "${log["Quantite"]} ${log["Unite"]}",
                    emission:
                        "${(log["Emission_Calculee"] ?? 0).toString()} kgCO₂e/an",
                    onEdit: () {
                      // ouverture écran d’édition si prévu
                    },
                    onDelete: () {
                      // suppression via API si souhaité
                    },
                  );
                },
              ),
    );
  }
}
