import 'poste_vehicule.dart';

double calculerTotalEmissionVehicule(PosteVehicule poste) {
  final facteur = poste.facteurEmission;
  final duree = poste.dureeAmortissement > 0 ? poste.dureeAmortissement : 1;
  final annee = poste.anneeAchat;
  final now = DateTime.now().year;
  final proprietaires = poste.nbProprietaires > 0 ? poste.nbProprietaires : 1;

  final age = now - annee + 1;
  if (age <= duree) {
    return poste.quantite * (facteur / duree) / proprietaires;
  }
  return 0;
}
