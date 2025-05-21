import '../../../data/classes/poste_vehicule.dart';

double calculerTotalEmissionVehicule(PosteVehicule poste) {
  final quantite = poste.quantite;
  final facteur = poste.facteurEmission;
  final duree = poste.dureeAmortissement > 0 ? poste.dureeAmortissement : 1;

  return (quantite * facteur) / duree;
}
