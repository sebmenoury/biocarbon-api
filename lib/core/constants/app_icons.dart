import 'package:flutter/material.dart';

final Map<String, IconData> categoryIcons = {
  "Logement": Icons.home,
  "Déplacements": Icons.directions_car,
  "Alimentation": Icons.restaurant,
  "Biens et services": Icons.shopping_bag,
  "Services publics": Icons.miscellaneous_services,
};

final Map<String, Color> categoryColors = {
  "Logement": Colors.teal,
  "Déplacements": Colors.indigo,
  "Alimentation": Colors.redAccent,
  "Biens et services": Colors.orange,
  "Services publics": Colors.purple,
};

final Map<String, IconData> sousCategorieIcons = {
  'Biens Immobiliers': Icons.home,
  'Construction': Icons.home,
  'Véhicules': Icons.directions_car,
  'Equipements Multi-media': Icons.devices,
  'Equipements Bricolage': Icons.handyman,
  'Equipements Ménager': Icons.kitchen,
  'Equipements Confort': Icons.thermostat,
  'Alimentation': Icons.restaurant,
  'Gaz et Fioul': Icons.local_gas_station,
  'Electricité': Icons.electrical_services,
  'Loisirs': Icons.sports_esports,
  'Habillement': Icons.checkroom,
  'Banque et Assurances': Icons.account_balance,
  'Déplacements Avion': Icons.flight_takeoff,
  'Déplacements Voiture': Icons.directions_car,
  'Déplacements Train/Métro/Bus': Icons.directions_transit,
  'Déplacements Autres': Icons.directions_bike,
  'Services publics': Icons.business,
  'Déchets et Eau': Icons.water_drop_sharp,
};

final Map<String, Color> souscategoryColors = {
  "Biens Immobiliers": Colors.teal,
  'Construction': Colors.teal,
  'Véhicules': Colors.indigo,
  'Equipements Multi-media': Colors.orange,
  'Equipements Bricolage': Colors.orange,
  'Equipements Ménager': Colors.orange,
  'Equipements Confort': Colors.teal,
  'Gaz et Fioul': Colors.teal,
  'Electricité': Colors.teal,
  "Alimentation": Colors.redAccent,
  'Loisirs': Colors.orange,
  'Habillement': Colors.orange,
  'Banque et Assurances': Colors.orange,
  'Déplacements Avion': Colors.indigo,
  'Déplacements Voiture': Colors.indigo,
  'Déplacements Train/Métro/Bus': Colors.indigo,
  'Déplacements Autres': Colors.indigo,
  "Biens et services": Colors.orange,
  "Services publics": Colors.purple,
  'Déchets et Eau': Colors.teal,
};
