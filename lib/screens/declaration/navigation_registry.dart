import 'package:flutter/material.dart';

// Importe ici tous tes écrans
import 'usage_alimentation/alimentation_screen.dart';
import 'usage_logement/usages_gaz_fioul_screen.dart';

import 'bien_immobilier/bien_declaration_screen.dart';
import 'usage_deplacements/deplacement_avion.dart';
import 'usage_loisirs/usages_loisirs.dart';
import 'usage_loisirs/usages_habillement.dart';
import 'usage_banque_assurance/usages_banque.dart';
import 'usage_deplacements/deplacement_voiture.dart';

/// Classe représentant une entrée de la registry : écran + titre
class ScreenRegistryEntry {
  final Widget Function() builder;
  final String titre;

  const ScreenRegistryEntry({required this.builder, required this.titre});
}

/// Map des écrans par Type_Categorie et Sous_Categorie
final Map<String, Map<String, ScreenRegistryEntry>> screenRegistry = {
  "Déplacements": {
    "Déplacements Avion": ScreenRegistryEntry(
      builder:
          () => AvionScreen(
            codeIndividu: 'BASILE', // tu peux injecter dynamiquement si tu as un contexte global
            valeurTemps: '2025', // ou une variable `selectedYear`
            sousCategorie: 'Déplacements Avion',
            onSave: () {}, // à adapter
          ),
      titre: "Mes déplacements en avion",
    ),
    "Déplacements Voiture": ScreenRegistryEntry(
      builder:
          () => DeplacementVoitureScreen(
            codeIndividu: 'BASILE',
            valeurTemps: '2025',
            sousCategorie: 'Déplacements Voiture',
            onSave: () {}, // callback à adapter
          ),
      titre: "Mes déplacements en voiture",
    ),
  },
  "Logement": {
    "Biens Immobiliers": ScreenRegistryEntry(
      builder: () => const BienDeclarationScreen(), // à adapter si besoin
      titre: "Type et propriété du logement",
    ),
  },
  "Biens et services": {
    "Loisirs": ScreenRegistryEntry(
      builder:
          () => UsagesLoisirsScreen(
            codeIndividu: 'BASILE', // à rendre dynamique si besoin
            valeurTemps: '2025',
            sousCategorie: 'Loisirs',
            onSave: () {}, // à adapter
          ),
      titre: "Mes différents loisirs",
    ),
    "Habillement": ScreenRegistryEntry(
      builder:
          () => UsagesHabillementScreen(
            codeIndividu: 'BASILE',
            valeurTemps: '2025',
            sousCategorie: 'Habillement',
            onSave: () {}, // à adapter
          ),
      titre: "Mes dépenses en habillement",
    ),
    "Banques et Assurances": ScreenRegistryEntry(
      builder:
          () => UsagesBanqueScreen(
            codeIndividu: 'BASILE',
            valeurTemps: '2025',
            sousCategorie: 'Banques et Assurances',
            onSave: () {}, // à adapter
          ),
      titre: "Mes comptes bancaires et assurances",
    ),
  },
};

/// Fonction utilitaire pour récupérer l'écran et le titre
ScreenRegistryEntry? getEcranEtTitre(String typeCategorie, String sousCategorie) {
  return screenRegistry[typeCategorie]?[sousCategorie];
}
