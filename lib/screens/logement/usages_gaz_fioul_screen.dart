import 'package:flutter/material.dart';

class UsagesGazFioulScreen extends StatefulWidget {
  const UsagesGazFioulScreen({super.key});

  @override
  State<UsagesGazFioulScreen> createState() => _UsagesGazFioulScreenState();
}

class _UsagesGazFioulScreenState extends State<UsagesGazFioulScreen> {
  int gazKwh = 11000;
  int fioulLitres = 0;
  int nbHabitants = 1; // À remplacer par une valeur récupérée depuis ton API ou session
  String codeIndividu = "BASILE"; // temporairement en dur
  int currentYear = DateTime.now().year;

  double facteurGaz = 231; // g CO₂/kWh (peut venir de Ref-Usage)
  double facteurFioul = 3251; // g CO₂/litre

  double? emissionGaz;
  double? emissionFioul;
  double? totalEmission;

  void calculerEtSauvegarder() {
    List<Map<String, dynamic>> donnees = [];

    if (gazKwh > 0) {
      final e = (gazKwh * facteurGaz) / nbHabitants;
      emissionGaz = e;
      donnees.add({"nom": "Chaudière gaz", "quantite": gazKwh, "unite": "kWh", "emission": emissionGaz});
    }

    if (fioulLitres > 0) {
      final e = (fioulLitres * facteurFioul) / nbHabitants;
      emissionFioul = e;
      donnees.add({"nom": "Fioul domestique", "quantite": fioulLitres, "unite": "litre", "emission": emissionFioul});
    }

    totalEmission = (emissionGaz ?? 0) + (emissionFioul ?? 0);

    // 🔁 Envoi des données vers ton backend (Google Sheets ou API)
    for (final d in donnees) {
      print("✅ Enregistrement : ${d['nom']} : ${d['emission']} kg CO₂/an");
      // TODO: POST vers ton API / Google Sheets ici
    }

    setState(() {}); // pour rafraîchir l'affichage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔥 Gaz et Fioul")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Déclaration de votre consommation de gaz ou fioul",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              "Indiquez vos consommations annuelles pour le chauffage ou la cuisson. Les émissions seront ajustées en fonction du nombre d’habitants.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Gaz (kWh/an)",
                prefixIcon: Icon(Icons.local_fire_department),
              ),
              keyboardType: TextInputType.number,
              initialValue: gazKwh.toString(),
              onChanged: (value) {
                setState(() {
                  gazKwh = int.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Fioul domestique (litres/an)",
                prefixIcon: Icon(Icons.oil_barrel),
              ),
              keyboardType: TextInputType.number,
              initialValue: fioulLitres.toString(),
              onChanged: (value) {
                setState(() {
                  fioulLitres = int.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: calculerEtSauvegarder,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer ma consommation"),
            ),
            const SizedBox(height: 24),
            if (totalEmission != null) ...[
              const Divider(),
              const Text("🌍 Estimation annuelle", style: TextStyle(fontWeight: FontWeight.bold)),
              if (emissionGaz != null) Text("🔥 Gaz : ${emissionGaz!.toStringAsFixed(1)} kg CO₂/an"),
              if (emissionFioul != null) Text("🛢️ Fioul : ${emissionFioul!.toStringAsFixed(1)} kg CO₂/an"),
              const SizedBox(height: 4),
              Text(
                "💨 Total : ${totalEmission!.toStringAsFixed(1)} kg CO₂/an",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
