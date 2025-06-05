import 'poste_bien_immobilier.dart';
import 'const_construction.dart';
import '../bien_immobilier/bien_immobilier.dart';

double calculerTotalEmission(
  PosteBienImmobilier poste,
  Map<String, double> facteursEmission,
  Map<String, int> dureesAmortissement, {
  required int nbProprietaires, // 👈 injecté depuis BienImmobilier
}) {
  final reduction = reductionParAnnee(poste.anneeConstruction);
  double total = 0.0;

  // 🔨 Équipement principal (maison / appart)
  total += (poste.surface * (facteursEmission[poste.nomEquipement] ?? 0) * reduction) / (dureesAmortissement[poste.nomEquipement] ?? 1) / nbProprietaires;

  // 🏠 Garage (si surface > 0)
  if (poste.surfaceGarage > 0) {
    total += (poste.surfaceGarage * (facteursEmission['Garage béton'] ?? 0) * reduction) / (dureesAmortissement['Garage béton'] ?? 1) / nbProprietaires;
  }

  // 🏊‍♂️ Piscine (si surface > 0)
  if (poste.surfacePiscine > 0) {
    total += (poste.surfacePiscine * (facteursEmission[poste.typePiscine] ?? 0) * reduction) / (dureesAmortissement[poste.typePiscine] ?? 1) / nbProprietaires;
  }

  // 🌿 Abri ou serre (si surface > 0)
  if (poste.surfaceAbriEtSerre > 0) {
    total += (poste.surfaceAbriEtSerre * (facteursEmission['Abri de jardin bois'] ?? 0) * reduction) / (dureesAmortissement['Abri de jardin bois'] ?? 1) / nbProprietaires;
  }

  return total;
}
