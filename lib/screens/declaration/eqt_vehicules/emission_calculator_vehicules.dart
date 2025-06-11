import '../../../data/classes/poste_vehicule.dart';

double calculerTotalEmissionVehicule(PosteVehicule poste) {
  final facteur = poste.facteurEmission;
  final duree = poste.dureeAmortissement > 0 ? poste.dureeAmortissement : 1;
  final annees = poste.anneeAchat;
  final now = DateTime.now().year;

  double total = 0;

  for (final annee in annees) {
    final age = now - annee + 1;
    if (age <= duree) {
      total += facteur / duree;
    }
  }

  return total;
}
