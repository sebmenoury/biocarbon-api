import 'package:flutter/material.dart';
import 'poste_avion.dart';
import '../../../data/classes/poste_postes.dart';
import '../../../data/services/api_service.dart';
import 'haversine.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import 'frequence_slider.dart';

class AvionScreen extends StatefulWidget {
  final String codeIndividu;
  final String valeurTemps;
  final String sousCategorie;

  const AvionScreen({super.key, required this.codeIndividu, required this.valeurTemps, required this.sousCategorie});

  @override
  State<AvionScreen> createState() => _AvionScreenState();
}

class _AvionScreenState extends State<AvionScreen> {
  List<Poste> vols = [];
  List<Map<String, dynamic>> tousLesAeroports = [];
  bool isLoading = false;

  String? selectedPaysDepart;
  String? selectedVilleDepart;
  String? selectedAeroportDepart;

  String? selectedPaysArrivee;
  String? selectedVilleArrivee;
  String? selectedAeroportArrivee;

  List<String> paysList = [];
  List<String> villesDepartList = [];
  List<String> villesArriveeList = [];
  List<String> aeroportsDepartList = [];
  List<String> aeroportsArriveeList = [];

  bool allerRetour = false;
  int selectedFrequence = 1;

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  void initState() {
    super.initState();
    _chargerBase();
  }

  Future<void> _chargerBase() async {
    setState(() => isLoading = true);
    try {
      await _chargerVols();
      tousLesAeroports = await ApiService.getRefAeroportsFull();
      paysList = tousLesAeroports.map((e) => e['Pays'] as String).toSet().toList();
    } catch (e) {
      showError(context, e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _chargerVilles(bool isDepart, String pays) {
    final villes = tousLesAeroports.where((a) => a['Pays'] == pays).map((e) => e['Ville'] as String).toSet().toList();

    setState(() {
      if (isDepart) {
        villesDepartList = villes;
        selectedVilleDepart = null;
        selectedAeroportDepart = null;
        aeroportsDepartList.clear();
      } else {
        villesArriveeList = villes;
        selectedVilleArrivee = null;
        selectedAeroportArrivee = null;
        aeroportsArriveeList.clear();
      }
    });
  }

  void _chargerAeroports(bool isDepart, String pays, String ville) {
    final aeroports = tousLesAeroports.where((a) => a['Pays'] == pays && a['Ville'] == ville).map((e) => e['Nom_Aeroport'] as String).toSet().toList();

    setState(() {
      if (isDepart) {
        aeroportsDepartList = aeroports;
        selectedAeroportDepart = null;
      } else {
        aeroportsArriveeList = aeroports;
        selectedAeroportArrivee = null;
      }
    });
  }

  Future<void> _chargerVols() async {
    vols = await ApiService.getUCPostesFiltres(codeIndividu: widget.codeIndividu, valeurTemps: widget.valeurTemps, sousCategorie: 'Déplacements Avion');
  }

  Future<void> _ajouterVol() async {
    if (selectedPaysDepart == null || selectedVilleDepart == null || selectedAeroportDepart == null || selectedPaysArrivee == null || selectedVilleArrivee == null || selectedAeroportArrivee == null) {
      return;
    }

    try {
      final d1 = tousLesAeroports.firstWhere((a) => a['Pays'] == selectedPaysDepart && a['Ville'] == selectedVilleDepart && a['Nom_Aeroport'] == selectedAeroportDepart);

      final d2 = tousLesAeroports.firstWhere((a) => a['Pays'] == selectedPaysArrivee && a['Ville'] == selectedVilleArrivee && a['Nom_Aeroport'] == selectedAeroportArrivee);

      final distance = Haversine.calculerDistanceKm(
        lat1: double.parse(d1['Latitude'].toString()),
        lon1: double.parse(d1['Longitude'].toString()),
        lat2: double.parse(d2['Latitude'].toString()),
        lon2: double.parse(d2['Longitude'].toString()),
      );

      final facteur = double.parse(d1['Facteur_Emission'].toString());
      final multiplicateur = allerRetour ? 2 : 1;
      final emission = distance * facteur * multiplicateur * selectedFrequence;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final idUsage = "TEMP-${timestamp}_${widget.sousCategorie}_${distance}_${widget.valeurTemps}".replaceAll(' ', '_');

      final poste = Poste(
        idUsage: idUsage,
        codeIndividu: widget.codeIndividu,
        typeTemps: 'Réel',
        valeurTemps: widget.valeurTemps,
        dateEnregistrement: DateTime.now().toIso8601String(),
        typeCategorie: 'Déplacements',
        sousCategorie: 'Déplacements Avion',
        typePoste: 'Usage',
        nomPoste: "$selectedAeroportDepart → $selectedAeroportArrivee" + (allerRetour ? " (AR)" : ""),
        quantite: distance,
        unite: 'km',
        facteurEmission: facteur,
        emissionCalculee: emission,
        frequence: selectedFrequence.toString(),
        modeCalcul: 'Direct',
      );

      // await ApiService.postPostes([poste]);
      await _chargerVols();
      setState(() {});
    } catch (e) {
      showError(context, e.toString());
    }
  }

  Widget _buildDropdownBloc({
    required bool isDepart,
    required String? selectedPays,
    required String? selectedVille,
    required String? selectedAeroport,
    required List<String> villesList,
    required List<String> aeroportsList,
    required void Function(String) onPaysChanged,
    required void Function(String) onVilleChanged,
    required void Function(String) onAeroportChanged,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(
            value: selectedPays,
            hint: const Text("Choisissez un pays"),
            isExpanded: true,
            items: paysList.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 11)))).toList(),
            onChanged: (val) {
              onPaysChanged(val!);
              _chargerVilles(isDepart, val);
            },
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: selectedVille,
            hint: const Text("Choisissez une ville"),
            isExpanded: true,
            items: villesList.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 11)))).toList(),
            onChanged: (val) {
              onVilleChanged(val!);
              _chargerAeroports(isDepart, selectedPays!, val);
            },
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: selectedAeroport,
            hint: const Text("Choisissez un aéroport"),
            isExpanded: true,
            items: aeroportsList.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 11)))).toList(),
            onChanged: (val) => onAeroportChanged(val!),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Stack(
        alignment: Alignment.center,
        children: [
          const Text("Déclaration de vos déplacements avion", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(icon: const Icon(Icons.arrow_back), iconSize: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context)),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sélection du trajet", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDropdownBloc(
                        isDepart: true,
                        selectedPays: selectedPaysDepart,
                        selectedVille: selectedVilleDepart,
                        selectedAeroport: selectedAeroportDepart,
                        villesList: villesDepartList,
                        aeroportsList: aeroportsDepartList,
                        onPaysChanged: (val) => setState(() => selectedPaysDepart = val),
                        onVilleChanged: (val) => setState(() => selectedVilleDepart = val),
                        onAeroportChanged: (val) => setState(() => selectedAeroportDepart = val),
                      ),
                      const SizedBox(width: 12),
                      _buildDropdownBloc(
                        isDepart: false,
                        selectedPays: selectedPaysArrivee,
                        selectedVille: selectedVilleArrivee,
                        selectedAeroport: selectedAeroportArrivee,
                        villesList: villesArriveeList,
                        aeroportsList: aeroportsArriveeList,
                        onPaysChanged: (val) => setState(() => selectedPaysArrivee = val),
                        onVilleChanged: (val) => setState(() => selectedVilleArrivee = val),
                        onAeroportChanged: (val) => setState(() => selectedAeroportArrivee = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Type de trajet : "),
                      Radio<bool>(value: false, groupValue: allerRetour, onChanged: (v) => setState(() => allerRetour = v!)),
                      const Text("Aller simple"),
                      Radio<bool>(value: true, groupValue: allerRetour, onChanged: (v) => setState(() => allerRetour = v!)),
                      const Text("Aller-retour"),
                    ],
                  ),
                  FrequenceSlider(selected: selectedFrequence, onChanged: (val) => setState(() => selectedFrequence = val)),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(icon: const Icon(Icons.flight_takeoff, size: 16), onPressed: _ajouterVol, label: const Text("Ajouter ce vol"))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: vols.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final vol = vols[index];
                  return CustomCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(vol.nomPoste ?? "Vol #$index", style: const TextStyle(fontSize: 13))),
                        Text("${vol.emissionCalculee.toStringAsFixed(1)} kgCO₂", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
