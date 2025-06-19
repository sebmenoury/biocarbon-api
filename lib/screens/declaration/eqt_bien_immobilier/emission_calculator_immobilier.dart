import 'poste_bien_immobilier.dart';
import 'const_construction.dart';
import '../bien_immobilier/bien_immobilier.dart';
import 'package:flutter/foundation.dart';

double calculerTotalEmission(PosteBienImmobilier poste, Map<String, double> facteursEmission, Map<String, int> dureesAmortissement, {required int nbProprietaires}) {
  double total = 0.0;
  final anneeActuelle = DateTime.now().year;

  // 🔨 Maison / appartement
  if (poste.surface > 0) {
    final facteur = facteursEmission[poste.typeConstruction];
    final duree = dureesAmortissement[poste.typeConstruction];
    final reduction = reductionParAnnee(poste.anneeConstruction);
    final age = anneeActuelle - poste.anneeConstruction;

    if (facteur != null && duree != null && age < duree) {
      total += (poste.surface * facteur * reduction) / duree / nbProprietaires;
    } else {
      debugPrint("⏳ Logement ignoré (amorti ou info manquante) pour '${poste.typeConstruction}'");
    }
  }

  // 🏠 Garage
  if (poste.surfaceGarage > 0) {
    final age = anneeActuelle - poste.anneeGarage;
    final duree = dureesAmortissement['Garage béton'];
    final reduction = reductionParAnnee(poste.anneeGarage);

    if (duree != null && age < duree) {
      total += (poste.surfaceGarage * (facteursEmission['Garage béton'] ?? 0) * reduction) / duree / nbProprietaires;
    } else {
      debugPrint("⏳ Garage ignoré (amorti ou info manquante)");
    }
  }

  // 🏊‍♂️ Piscine
  if (poste.surfacePiscine > 0) {
    final facteur = facteursEmission[poste.typePiscine];
    final duree = dureesAmortissement[poste.typePiscine];
    final reduction = reductionParAnnee(poste.anneePiscine);
    final age = anneeActuelle - poste.anneePiscine;

    if (facteur != null && duree != null && age < duree) {
      total += (poste.surfacePiscine * facteur * reduction) / duree / nbProprietaires;
    } else {
      debugPrint("⏳ Piscine ignorée (amorti ou info manquante) pour '${poste.typePiscine}'");
    }
  }

  // 🌿 Abri / serre
  if (poste.surfaceAbriEtSerre > 0) {
    final age = anneeActuelle - poste.anneeAbri;
    final duree = dureesAmortissement['Abri de jardin bois'];
    final reduction = reductionParAnnee(poste.anneeAbri);

    if (duree != null && age < duree) {
      total += (poste.surfaceAbriEtSerre * (facteursEmission['Abri de jardin bois'] ?? 0) * reduction) / duree / nbProprietaires;
    } else {
      debugPrint("⏳ Abri/serre ignoré (amorti ou info manquante)");
    }
  }

  return total;
}
