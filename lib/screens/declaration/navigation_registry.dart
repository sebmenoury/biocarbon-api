import 'package:flutter/material.dart';

// Importe ici tous tes écrans
import 'usage_alimentation/alimentation_screen.dart';
import 'usage_logement/usages_gaz_fioul_screen.dart';

import 'bien_immobilier/bien_declaration_screen.dart';

/// Classe représentant une entrée de la registry : écran + titre
class ScreenRegistryEntry {
  final Widget Function() builder;
  final String titre;

  const ScreenRegistryEntry({required this.builder, required this.titre});
}

/// Map des écrans par Type_Categorie et Sous_Categorie
final Map<String, Map<String, ScreenRegistryEntry>> screenRegistry = {
  "Alimentation": {"Général": ScreenRegistryEntry(builder: () => const AlimentationScreen(), titre: "Déclaration de l'alimentation")},
  "Logement": {
    "Gaz et Fioul": ScreenRegistryEntry(builder: () => const UsagesGazFioulScreen(), titre: "Déclaration Gaz et Fioul"),
    "Biens Immobiliers": ScreenRegistryEntry(
      builder: () => const BienDeclarationScreen(), // à adapter si besoin
      titre: "Type et propriété du logement",
    ),
  },
};

/// Fonction utilitaire pour récupérer l'écran et le titre
ScreenRegistryEntry? getEcranEtTitre(String typeCategorie, String sousCategorie) {
  return screenRegistry[typeCategorie]?[sousCategorie];
}
