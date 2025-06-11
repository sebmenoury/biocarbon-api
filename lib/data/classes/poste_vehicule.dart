import 'poste_postes.dart';

class PosteVehicule {
  String nomEquipement;
  int anneeAchat;
  double facteurEmission;
  int dureeAmortissement;

  PosteVehicule({required this.nomEquipement, required this.anneeAchat, this.facteurEmission = 0, this.dureeAmortissement = 1});

  /// Méthode statique : retourne la sous-catégorie en fonction du nom
  static String getSousCategorieFromNom(String nom) {
    final nomMin = nom.toLowerCase();

    if (nomMin.contains("Voitures")) {
      return "Voitures";
    } else if (nomMin.contains("2-roues") || nomMin.contains("moto") || nomMin.contains("scooter")) {
      return "2 roues";
    } else {
      return "Autres";
    }
  }

  /// Regroupe une liste de postes en Map<sousCat, liste>
  static Map<String, List<Poste>> groupBySousCategorie(List<Poste> postes) {
    final Map<String, List<Poste>> grouped = {};

    for (var poste in postes) {
      final nom = poste.nomPoste ?? "";
      final sousCat = getSousCategorieFromNom(nom);

      grouped.putIfAbsent(sousCat, () => []).add(poste);
    }

    return grouped;
  }
}
