import 'package:flutter/material.dart';

class AlimentationScreen extends StatefulWidget {
  const AlimentationScreen({super.key});

  @override
  State<AlimentationScreen> createState() => _AlimentationScreenState();
}

class _AlimentationScreenState extends State<AlimentationScreen> {
  final Map<String, Map<String, dynamic>> regimes = {
    "Carnivore ++": {"emoji": "🍖", "desc": "Viande à chaque repas, produits animaux fréquents.", "emission": 2100},
    "Carnivore": {"emoji": "🥩", "desc": "1 viande par jour. Produits laitiers fréquents.", "emission": 1700},
    "Flexitarien": {"emoji": "🍗", "desc": "Viande/poisson 3–4 fois/semaine. Légumes réguliers.", "emission": 950},
    "Végétarien": {"emoji": "🥚", "desc": "Sans viande/poisson. Œufs et laitages présents.", "emission": 700},
    "Végan": {"emoji": "🌿", "desc": "100% végétal. Aucun produit animal.", "emission": 550},
  };

  String? selectedRegime;
  double? selectedEmission;

  void _choisirRegime(String nom) {
    setState(() {
      selectedRegime = nom;
      selectedEmission = regimes[nom]!['emission'].toDouble();
    });

    // TODO : ici tu peux appeler un POST vers ton API Google Sheets
    print("✅ Régime choisi : $nom / ${selectedEmission} kg CO₂/an");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🥗 Régime alimentaire")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quel est votre régime alimentaire ?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Estimation basée sur votre comportement alimentaire moyen hebdomadaire.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
              children:
                  regimes.entries.map((entry) {
                    final nom = entry.key;
                    final info = entry.value;
                    final isSelected = nom == selectedRegime;

                    return GestureDetector(
                      onTap: () => _choisirRegime(nom),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.shade100 : Colors.white,
                          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Text(info['emoji'], style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(info['desc'], style: const TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            if (selectedRegime != null) ...[
              const Divider(),
              Text(
                "🧾 Régime sélectionné : $selectedRegime",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                "🌍 Empreinte estimée : ${selectedEmission!.toStringAsFixed(0)} kg CO₂/an",
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
