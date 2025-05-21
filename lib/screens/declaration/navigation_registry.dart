import 'package:flutter/material.dart';

// Importe ici tous tes écrans de déclaration
import 'usage_alimentation/alimentation_screen.dart';
import 'eqt_bien_immobilier/usages_gaz_fioul_screen.dart';
import 'eqt_vehicules/vehicule_screen.dart';
// etc...

/// Cette fonction retourne l’écran Flutter approprié
/// en fonction du type de catégorie et de la sous-catégorie.

Widget? getEcranEdition(String typeCategorie, String sousCategorie) {
  switch (typeCategorie) {
    case "Alimentation":
      return const AlimentationScreen();

    case "Logement":
      if (sousCategorie == "Gaz et fioul") {
        return const UsagesGazFioulScreen();
      }
      break;

    case "Véhicules":
      if (sousCategorie == "Véhicules") {
        return const VehiculeScreen();
      }
    // Ajoute ici d’autres cas au besoin :
    // case "Biens":
    //   return const BiensScreen();

    default:
      return null;
  }
}
