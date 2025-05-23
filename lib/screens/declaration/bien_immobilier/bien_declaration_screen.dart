import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';

class BienDeclarationScreen extends StatefulWidget {
  const BienDeclarationScreen({super.key});

  @override
  State<BienDeclarationScreen> createState() => _BienDeclarationScreenState();
}

class _BienDeclarationScreenState extends State<BienDeclarationScreen> {
  String typeBien = 'Maison principale';
  String denomination = '';
  String adresse = '';
  bool inclureDansBilan = true;
  int nbProprietaires = 2;

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
  Widget build(BuildContext context) {
    return BaseScreen(
      title: const Text("Bien immobilier", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      children: [
        CustomCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.home, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DropdownButton<String>(
                      value: typeBien,
                      onChanged: (val) => setState(() => typeBien = val ?? 'Maison principale'),
                      items: const [
                        DropdownMenuItem(value: 'Maison principale', child: Text('Maison principale')),
                        DropdownMenuItem(value: 'Maison secondaire', child: Text('Maison secondaire')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: denomination,
                onChanged: (val) => setState(() => denomination = val),
                decoration: const InputDecoration(labelText: "Dénomination"),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: adresse,
                onChanged: (val) => setState(() => adresse = val),
                decoration: const InputDecoration(labelText: "Adresse"),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(value: inclureDansBilan, onChanged: (val) => setState(() => inclureDansBilan = val ?? true)),
                  const Text("Inclure dans le bilan"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CustomCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nombre de propriétaires", style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: decrementProprietaires),
                  Text("$nbProprietaires", style: const TextStyle(fontSize: 14)),
                  IconButton(icon: const Icon(Icons.add), onPressed: incrementProprietaires),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
