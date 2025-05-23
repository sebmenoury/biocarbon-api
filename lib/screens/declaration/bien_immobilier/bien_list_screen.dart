import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';

class BienListScreen extends StatefulWidget {
  const BienListScreen({super.key});

  @override
  State<BienListScreen> createState() => _BienListScreenState();
}

class _BienListScreenState extends State<BienListScreen> {
  late Future<List<Map<String, dynamic>>> biensFuture;

  @override
  void initState() {
    super.initState();
    biensFuture = ApiService.getBiens("BASILE");
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 18,
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text("Mes biens immobiliers", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: biensFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasError) {
              return Padding(padding: const EdgeInsets.all(16), child: Text("Erreur : ${snapshot.error}"));
            }

            final biens = snapshot.data ?? [];
            if (biens.isEmpty) {
              return const Padding(padding: EdgeInsets.all(16), child: Text("Aucun bien immobilier déclaré."));
            }

            return Column(
              children:
                  biens.map((bien) {
                    final type = bien['Type_Bien'] ?? '';
                    final denom = bien['Dénomination'] ?? '';
                    final adresse = bien['Adresse'] ?? '';
                    final nbProp = bien['Nb_Proprietaires']?.toString() ?? '-';
                    final inclure = bien['Inclure_dans_Bilan'] == true;

                    return CustomCard(
                      padding: const EdgeInsets.all(12),
                      // margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.home, size: 16),
                              const SizedBox(width: 6),
                              Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("Dénomination : $denom", style: const TextStyle(fontSize: 12)),
                          Text("Adresse : $adresse", style: const TextStyle(fontSize: 12)),
                          Text("Nombre Propriétaires : $nbProp", style: const TextStyle(fontSize: 12)),
                          if (inclure)
                            const Text(
                              "Inclus dans le bilan",
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }
}
