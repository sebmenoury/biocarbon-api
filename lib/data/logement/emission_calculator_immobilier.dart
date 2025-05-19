import 'poste_bien_immobilier.dart';
import 'const_construction.dart';

double calculerTotalEmission(
  PosteBienImmobilier bien,
  Map<String, double> facteursEmission,
  Map<String, int> dureesAmortissement,
) {
  final reduction = reductionParAnnee(bien.anneeConstruction);
  double total = 0.0;

  total +=
      (bien.surface * (facteursEmission[bien.nomEquipement] ?? 0) * reduction) /
      (dureesAmortissement[bien.nomEquipement] ?? 1) /
      bien.nbProprietaires;

  if (bien.garage) {
    total +=
        (bien.surfaceGarage *
            (facteursEmission['Garage béton'] ?? 0) *
            reduction) /
        (dureesAmortissement['Garage béton'] ?? 1) /
        bien.nbProprietaires;
  }

  if (bien.piscine) {
    final surfacePiscine = bien.piscineLargeur * bien.piscineLongueur;
    total +=
        (surfacePiscine *
            (facteursEmission[bien.typePiscine] ?? 0) *
            reduction) /
        (dureesAmortissement[bien.typePiscine] ?? 1) /
        bien.nbProprietaires;
  }

  if (bien.abriEtSerre) {
    total +=
        (bien.surfaceAbriEtSerre *
            (facteursEmission['Abri de jardin bois'] ?? 0) *
            reduction) /
        (dureesAmortissement['Abri de jardin bois'] ?? 1) /
        bien.nbProprietaires;
  }

  return total;
}
