import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../logement/logement_list_screen.dart';

class MesDonneesScreen extends StatefulWidget {
  const MesDonneesScreen({super.key});

  @override
  State<MesDonneesScreen> createState() => _MesDonneesScreenState();
}

class _MesDonneesScreenState extends State<MesDonneesScreen> {
  int selectedIndex = 0; // 0 = Equipements, 1 = Usages

  @override
  Widget build(BuildContext context) {
    final equipementItems = [
      {'icon': Icons.directions_bike, 'label': 'Véhicules'},
      {'icon': Icons.home, 'label': 'Logements'},
      {'icon': Icons.local_laundry_service, 'label': 'Equipements ménagers'},
      {'icon': Icons.smartphone, 'label': 'Equipements multi-média'},
      {'icon': Icons.handyman, 'label': 'Equipements bricolage'},
    ];

    final usageItems = [
      {
        'icon': Icons.directions_walk,
        'label': 'Déplacement quotidien / loisirs',
      },
      {'icon': Icons.thermostat, 'label': 'Chauffage/Climatisation'},
      {'icon': Icons.local_dining, 'label': 'Alimentation'},
      {'icon': Icons.card_travel, 'label': 'Loisirs'},
      {'icon': Icons.checkroom, 'label': 'Habillement'},
      {'icon': Icons.account_balance, 'label': 'Banque et assurance'},
      {'icon': Icons.account_balance_outlined, 'label': 'Services publics'},
    ];

    final currentItems = selectedIndex == 0 ? equipementItems : usageItems;

    return BaseScreen(
      title: "Mes données",
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          selectedIndex == 0
                              ? Colors.indigo
                              : Colors.grey.shade200,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Equipements",
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedIndex == 0 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          selectedIndex == 1
                              ? Colors.indigo
                              : Colors.grey.shade200,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(20),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Usages",
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedIndex == 1 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: currentItems.length,
          itemBuilder: (context, index) {
            final item = currentItems[index];
            return CustomCard(
              onTap: () {
                if (item['label'] == 'Logements') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LogementListScreen(),
                    ),
                  );
                } else {
                  // TODO: Navigate to other screens as needed
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
