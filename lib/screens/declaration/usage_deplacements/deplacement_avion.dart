import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
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

  double? emissionEstimee;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _chargerBase());
  }

  Future<void> _chargerBase() async {
    setState(() => isLoading = true);
    try {
      await _chargerVols();
      tousLesAeroports = await ApiService.getRefAeroportsFull();

      // Extraire les pays distincts, supprimer les nuls, et trier par ordre alphabétique
      paysList = tousLesAeroports.map((e) => e['Pays']?.toString() ?? '').where((p) => p.isNotEmpty).toSet().toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } catch (e) {
      showError(context, e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _chargerVilles(bool isDepart, String pays) {
    final villes =
        tousLesAeroports.where((a) => a['Pays'] == pays).map((e) => e['Ville']?.toString() ?? '').where((v) => v.isNotEmpty).toSet().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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
    final aeroports =
        tousLesAeroports.where((a) => a['Pays'] == pays && a['Ville'] == ville).map((e) => e['Nom_Aeroport']?.toString() ?? '').where((a) => a.isNotEmpty).toSet().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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

  Future<void> _calculerEmissionEstimee() async {
    if (selectedPaysDepart == null || selectedVilleDepart == null || selectedAeroportDepart == null || selectedPaysArrivee == null || selectedVilleArrivee == null || selectedAeroportArrivee == null) {
      setState(() => emissionEstimee = null);
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

      final facteur =
          (distance > 5500)
              ? 0.1520
              : (distance >= 500)
              ? 0.1870
              : 0.2590;

      final multiplicateur = (allerRetour ? 2 : 1) * selectedFrequence;
      final emission = distance * facteur * multiplicateur;

      setState(() => emissionEstimee = emission);
    } catch (_) {
      setState(() => emissionEstimee = null);
    }
  }

  Future<void> _ajouterVol() async {
    if (selectedPaysDepart == null || selectedVilleDepart == null || selectedAeroportDepart == null || selectedPaysArrivee == null || selectedVilleArrivee == null || selectedAeroportArrivee == null) {
      showError(context, "Merci de compléter tous les champs avant d'ajouter un vol.");
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

      final facteur =
          (distance > 5500)
              ? 0.1520
              : (distance >= 500)
              ? 0.1870
              : 0.2590;

      final multiplicateur = (allerRetour ? 2 : 1) * selectedFrequence;
      final emission = distance * facteur * multiplicateur;

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
      setState(() {
        emissionEstimee = null;
      });
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
          DropdownSearch<String>(
            items: [...paysList]..sort(),
            selectedItem: selectedPays,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: const InputDecoration(labelText: "Choisissez un pays", labelStyle: TextStyle(fontSize: 11), contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 12)),
            ),
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(autofocus: true, style: const TextStyle(fontSize: 11)), // 👈 Autofocus ici
              itemBuilder: (context, item, isSelected) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(item, style: const TextStyle(fontSize: 11))),
            ),
            dropdownBuilder: (context, selectedItem) => Text(selectedItem ?? "", style: const TextStyle(fontSize: 11)),
            onChanged: (val) {
              if (val != null) {
                onPaysChanged(val);
                _chargerVilles(isDepart, val);
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownSearch<String>(
            items: [...villesList]..sort(),
            selectedItem: selectedVille,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: const InputDecoration(
                labelText: "Choisissez une ville",
                labelStyle: TextStyle(fontSize: 11),
                contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              ),
            ),
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(autofocus: true, style: const TextStyle(fontSize: 11)), // 👈 Autofocus ici aussi
              itemBuilder: (context, item, isSelected) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(item, style: const TextStyle(fontSize: 11))),
            ),
            dropdownBuilder: (context, selectedItem) => Text(selectedItem ?? "", style: const TextStyle(fontSize: 11)),
            onChanged: (val) {
              if (val != null && selectedPays != null) {
                onVilleChanged(val);
                _chargerAeroports(isDepart, selectedPays, val);
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownSearch<String>(
            items: [...aeroportsList]..sort(),
            selectedItem: selectedAeroport,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: const InputDecoration(
                labelText: "Choisissez un aéroport",
                labelStyle: TextStyle(fontSize: 11),
                contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              ),
            ),
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(autofocus: true, style: const TextStyle(fontSize: 11)), // 👈 Et encore ici
              itemBuilder: (context, item, isSelected) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(item, style: const TextStyle(fontSize: 11))),
            ),
            dropdownBuilder: (context, selectedItem) => Text(selectedItem ?? "", style: const TextStyle(fontSize: 11)),
            onChanged: (val) {
              if (val != null) {
                onAeroportChanged(val);
                _calculerEmissionEstimee();
              }
            },
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
                      Radio<bool>(
                        value: false,
                        groupValue: allerRetour,
                        onChanged: (v) {
                          setState(() => allerRetour = v!);
                          _calculerEmissionEstimee();
                        },
                      ),
                      const Text("Aller simple"),
                      Radio<bool>(
                        value: true,
                        groupValue: allerRetour,
                        onChanged: (v) {
                          setState(() => allerRetour = v!);
                          _calculerEmissionEstimee();
                        },
                      ),
                      const Text("Aller-retour"),
                    ],
                  ),
                  FrequenceSlider(
                    selected: selectedFrequence,
                    onChanged: (val) {
                      setState(() => selectedFrequence = val);
                      _calculerEmissionEstimee();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (emissionEstimee != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text("Émission estimée : ", style: TextStyle(fontSize: 12)),
                          Text("${emissionEstimee!.toStringAsFixed(1)} kgCO₂", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

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
