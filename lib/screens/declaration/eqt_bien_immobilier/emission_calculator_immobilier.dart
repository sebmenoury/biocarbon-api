import 'poste_bien_immobilier.dart';
import 'const_construction.dart';
import '../bien_immobilier/bien_immobilier.dart';
import 'package:flutter/foundation.dart';

double calculerTotalEmission(PosteBienImmobilier poste, Map<String, double> facteursEmission, Map<String, int> dureesAmortissement, {required int nbProprietaires}) {
  final reduction = reductionParAnnee(poste.anneeConstruction);
  double total = 0.0;

  // 🔨 Maison / appartement
  if (poste.surface > 0) {
    final facteur = facteursEmission[poste.nomEquipement];
    final duree = dureesAmortissement[poste.nomEquipement];

    if (facteur == null || duree == null) {
      debugPrint("⚠️ Logement ignoré : facteur ou durée manquante pour '${poste.nomEquipement}'");
    } else {
      total += (poste.surface * facteur * reduction) / duree / nbProprietaires;
    }
  }

  // 🏠 Garage
  if (poste.surfaceGarage > 0) {
    total += (poste.surfaceGarage * (facteursEmission['Garage béton'] ?? 0) * reduction) / (dureesAmortissement['Garage béton'] ?? 1) / nbProprietaires;
  }

  // 🏊‍♂️ Piscine
  if (poste.surfacePiscine > 0) {
    final facteur = facteursEmission[poste.typePiscine];
    final duree = dureesAmortissement[poste.typePiscine];

    if (facteur == null || duree == null) {
      debugPrint("⚠️ Piscine ignorée : facteur ou durée manquante pour '${poste.typePiscine}'");
    } else {
      total += (poste.surfacePiscine * facteur * reductionParAnnee(poste.anneePiscine)) / duree / nbProprietaires;
    }
  }

  // 🌿 Abri / serre
  if (poste.surfaceAbriEtSerre > 0) {
    total += (poste.surfaceAbriEtSerre * (facteursEmission['Abri de jardin bois'] ?? 0) * reduction) / (dureesAmortissement['Abri de jardin bois'] ?? 1) / nbProprietaires;
  }

  return total;
}
