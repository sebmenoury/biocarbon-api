import 'package:flutter/material.dart';

const Map<String, double> dureeAmortissement = {
  'Maison classique': 50,
  'Maison bois': 50,
  'Maison passive': 50,
  'Appartement': 50,
  'Appartement BBC': 50,
  'Garage béton': 50,
  'Piscine béton': 25,
  'Piscine coque': 20,
  'Abri/Serre de jardin': 20,
};

double reductionParAnnee(int annee) {
  if (annee >= 2024) return 0.6;
  if (annee >= 2020) return 0.85;
  if (annee >= 2010) return 1;
  if (annee >= 1990) return 0.85;
  if (annee >= 1975) return 0.7;
  if (annee >= 1950) return 0.6;
  if (annee >= 1900) return 0.4;
  return 1.0;
}

const Map<String, double> emissionFactors = {
  'Maison classique': 500.0,
  'Maison bois': 400.0,
  'Maison passive': 350.0,
  'Appartement': 450.0,
  'Appartement BBC': 350.0,
  'Garage béton': 290.0,
  'Piscine béton': 350.0,
  'Piscine coque': 230.0,
  'Abri/Serre de jardin': 100.0,
};

class BienImmobilier {
  String type;
  double surface;
  int anneeConstruction;
  int nbProprietaires;
  double surfaceGarage;
  bool garage;
  bool piscine;
  String typePiscine;
  double piscineLongueur;
  double piscineLargeur;
  bool abriEtSerre;
  double surfaceAbriEtSerre;

  BienImmobilier({
    required this.type,
    this.surface = 100,
    this.anneeConstruction = 2010,
    this.nbProprietaires = 1,
    this.surfaceGarage = 30,
    this.garage = false,
    this.piscine = false,
    this.typePiscine = "Piscine béton",
    this.piscineLongueur = 4,
    this.piscineLargeur = 2.5,
    this.abriEtSerre = false,
    this.surfaceAbriEtSerre = 10,
  });
}

class ConstructionScreen extends StatefulWidget {
  const ConstructionScreen({super.key});

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  List<BienImmobilier> biens = [BienImmobilier(type: "Maison classique")];

  double calculerTotalEmission() {
    double total = 0.0;
    for (final bien in biens) {
      final reduction = reductionParAnnee(bien.anneeConstruction);
      final type = bien.type;

      double logementCO2 = (bien.surface * (emissionFactors[type] ?? 0) * reduction) / dureeAmortissement[type]!;
      logementCO2 /= bien.nbProprietaires;
      total += logementCO2;

      if (bien.garage) {
        double garageCO2 = (bien.surfaceGarage * emissionFactors['Garage béton']! * reduction) / dureeAmortissement['Garage béton']!;
        garageCO2 /= bien.nbProprietaires;
        total += garageCO2;
      }
      if (bien.piscine) {
        final surfacePiscine = bien.piscineLargeur * bien.piscineLongueur;
        final facteurPiscine = emissionFactors[bien.typePiscine] ?? 300;
        double piscineCO2 = (surfacePiscine * facteurPiscine * reduction) / dureeAmortissement[bien.typePiscine]!;
        piscineCO2 /= bien.nbProprietaires;
        total += piscineCO2;
      }
      if (bien.abriEtSerre) {
        double abriCO2 = (bien.surfaceAbriEtSerre * emissionFactors['Abri/Serre de jardin']! * reduction) / dureeAmortissement['Abri/Serre de jardin']!;
        abriCO2 /= bien.nbProprietaires;
        total += abriCO2;
      }
    }
    return total; // en kgCO2/an
  }

  @override
  Widget build(BuildContext context) {
    final total = calculerTotalEmission();
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 390,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            children: [
              Row(
                children: [
                  const Text("📋 Déclaration des logements", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Card(
                  color: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text("🌍 Total estimé : ${total.toStringAsFixed(1)} kg CO₂/an",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              for (int i = 0; i < biens.length; i++)
                BienImmobilierForm(
                  bien: biens[i],
                  onRemove: () => setState(() => biens.removeAt(i)),
                  onUpdate: () => setState(() {}),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => biens.add(BienImmobilier(type: "Maison classique"))),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text("Ajouter un logement", style: TextStyle(fontSize: 12)),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.save, size: 14),
                    label: const Text("Enregistrer", style: TextStyle(fontSize: 12)),
                  )
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class BienImmobilierForm extends StatelessWidget {
  final BienImmobilier bien;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const BienImmobilierForm({super.key, required this.bien, required this.onRemove, required this.onUpdate});

  Widget champ(String label, double value, void Function(double) onChanged, {bool allowDecimal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10))),
          IconButton(icon: const Icon(Icons.remove, size: 12), onPressed: () => onChanged(value - 1)),
          SizedBox(
            width: 50,
            child: TextField(
              controller: TextEditingController(text: allowDecimal ? value.toStringAsFixed(1) : value.toInt().toString()),
              onChanged: (v) => onChanged(double.tryParse(v) ?? value),
              keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(icon: const Icon(Icons.add, size: 12), onPressed: () => onChanged(value + 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              isExpanded: true,
              style: const TextStyle(fontSize: 10),
              value: bien.type,
              items: emissionFactors.keys
                  .where((k) => ['Maison', 'Appartement'].any((e) => k.startsWith(e)))
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => {bien.type = val!, onUpdate()},
            ),
            champ("Surface (m²)", bien.surface, (v) => {bien.surface = v, onUpdate()}),
            champ("Année de construction", bien.anneeConstruction.toDouble(), (v) => {
              bien.anneeConstruction = v.toInt(),
              onUpdate()
            }),
            champ("Nb. propriétaires", bien.nbProprietaires.toDouble(), (v) => {
              bien.nbProprietaires = v.toInt(),
              onUpdate()
            }),
            const Divider(),
            CheckboxListTile(
              dense: true,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              contentPadding: EdgeInsets.zero,
              title: const Text("J’ai un garage", style: TextStyle(fontSize: 10)),
              value: bien.garage,
              onChanged: (val) => {bien.garage = val!, onUpdate()},
            ),
            if (bien.garage)
              champ("Surface garage (m²)", bien.surfaceGarage, (v) => {bien.surfaceGarage = v, onUpdate()}),
            const Divider(),
            CheckboxListTile(
              dense: true,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              contentPadding: EdgeInsets.zero,
              title: const Text("J’ai une piscine", style: TextStyle(fontSize: 10)),
              value: bien.piscine,
              onChanged: (val) => {bien.piscine = val!, onUpdate()},
            ),
            if (bien.piscine) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: bien.typePiscine,
                  style: const TextStyle(fontSize: 10),
                  items: ['Piscine béton', 'Piscine coque']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => {bien.typePiscine = val!, onUpdate()},
                ),
              ),
              champ("Longueur piscine (m)", bien.piscineLongueur, (v) => {bien.piscineLongueur = v, onUpdate()}, allowDecimal: true),
              champ("Largeur piscine (m)", bien.piscineLargeur, (v) => {bien.piscineLargeur = v, onUpdate()}, allowDecimal: true),
            ],
            const Divider(),
            CheckboxListTile(
              dense: true,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              contentPadding: EdgeInsets.zero,
              title: const Text("J’ai une construction dans mon jardin (abri ou serre)", style: TextStyle(fontSize: 10)),
              value: bien.abriEtSerre,
              onChanged: (val) => {bien.abriEtSerre = val!, onUpdate()},
            ),
            if (bien.abriEtSerre)
              champ("Surface abri/serre (m²)", bien.surfaceAbriEtSerre, (v) => {bien.surfaceAbriEtSerre = v, onUpdate()}),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text("Supprimer", style: TextStyle(fontSize: 10)),
              ),
            )
          ],
        ),
      ),
    );
  }
}