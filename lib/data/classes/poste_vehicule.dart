import 'poste.dart';
import '../services/api_service.dart';

class PosteVehicule {
  final String nomEquipement;
  List<int> anneesConstruction;
  double facteurEmission;
  int dureeAmortissement;

  PosteVehicule({
    required this.nomEquipement,
    required this.anneesConstruction,
    this.facteurEmission = 0,
    this.dureeAmortissement = 1,
  });

  // ✅ Ajoute ce getter :
  int get quantite => anneesConstruction.length;

  String getSousCategorieFromNom(String nomEquipement) {
    final nom = nomEquipement.toLowerCase();

    if (nom.contains("voiture") || nom.contains("suv")) {
      return "Voiture";
    } else if (nom.contains("scooter") || nom.contains("moto") || nom.contains("vélo") || nom.contains("velo")) {
      return "2 roues";
    } else {
      return "Autres";
    }
  }

  /// Conversion vers une liste de Postes (1 par véhicule déclaré)
  List<Poste> toPostes({required String codeIndividu, required double facteurEmission}) {
    return anneesConstruction.map((annee) {
      return Poste(
        idUsage: "", // généré plus tard (ou par backend)
        typeCategorie: "Véhicules",
        sousCategorie: getSousCategorieFromNom(nomEquipement),
        typePoste: "Equipement",
        nomPoste: nomEquipement,
        idBien: null,
        typeBien: null,
        quantite: 1,
        unite: "unité",
        emissionCalculee: facteurEmission, // déjà au format total par unité
        frequence: facteurEmission.toString(), // ou autre usage
        anneeAchat: annee,
        dureeAmortissement: null,
      );
    }).toList();
  }
}
