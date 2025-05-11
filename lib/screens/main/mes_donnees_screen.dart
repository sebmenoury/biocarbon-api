import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';

class MesDonneesScreen extends StatefulWidget {
  const MesDonneesScreen({super.key});

  @override
  State<MesDonneesScreen> createState() => _MesDonneesScreenState();
}

class _MesDonneesScreenState extends State<MesDonneesScreen> {
  String filtre = "Equipements"; // "Equipements" ou "Usages"

  final Map<String, List<Map<String, dynamic>>> sousCategories = {
    "Equipements": [
      {"nom": "Véhicules", "icon": Icons.directions_bike},
      {"nom": "Logements", "icon": Icons.house},
      {"nom": "Equipements ménagers", "icon": Icons.local_laundry_service},
      {"nom": "Equipements multi-média", "icon": Icons.smartphone},
      {"nom": "Equipements bricolage", "icon": Icons.precision_manufacturing},
    ],
    "Usages": [
      {"nom": "Déplacement quotidien / loisirs", "icon": Icons.directions_walk},
      {"nom": "Chauffage/Climatisation", "icon": Icons.thermostat},
      {"nom": "Alimentation", "icon": Icons.local_dining},
      {"nom": "Loisirs", "icon": Icons.card_travel},
      {"nom": "Habillement", "icon": Icons.checkroom},
      {"nom": "Banque et assurance", "icon": Icons.account_balance},
      {"nom": "Services publics", "icon": Icons.settings},
    ],
  };

  void ouvrirFormulaire(String nom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.6,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(16),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      "Saisie : $nom",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Formulaire à venir ici..."),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentList = sousCategories[filtre]!;

    return BaseScreen(
      title: "Mes données",
      children: [
        CustomCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                ["Equipements", "Usages"].map((option) {
                  final isSelected = filtre == option;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => filtre = option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.indigo : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.indigo : Colors.white,
                          ),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        CustomCard(
          padding: const EdgeInsets.all(8),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
            physics: const NeverScrollableScrollPhysics(),
            children:
                currentList.map((item) {
                  return GestureDetector(
                    onTap: () => ouvrirFormulaire(item['nom']),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item['icon'], size: 36, color: Colors.black87),
                          const SizedBox(height: 8),
                          Text(
                            item['nom'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
