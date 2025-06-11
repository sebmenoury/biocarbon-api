import 'poste_postes.dart';

class PosteVehicule {
  final String nomEquipement;
  int anneeAchat;
  final double facteurEmission;
  final int dureeAmortissement;

  // 🔽 Ajoute ces deux champs :
  final String? idBien;
  final String? typeBien;

  // 🔽 Et optionnellement le nombre de propriétaires (si pas déjà présent) :
  final int nbProprietaires;

  int quantite; // 👈 AJOUT ICI

  PosteVehicule({
    required this.nomEquipement,
    required this.anneeAchat,
    required this.facteurEmission,
    required this.dureeAmortissement,
    required this.nbProprietaires,
    this.idBien,
    this.typeBien,
    this.quantite = 1, // 👈 Valeur par défaut
  });

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

  Map<String, dynamic> toMap({required String codeIndividu, required String typeTemps, required String valeurTemps}) {
    final now = DateTime.now().toIso8601String();
    final idUsage = "${codeIndividu}_${typeTemps}_${valeurTemps}_${nomEquipement.replaceAll(' ', '_')}_$anneeAchat";

    return {
      "ID_Usage": idUsage,
      "Code_Individu": codeIndividu,
      "Type_Temps": typeTemps,
      "Valeur_Temps": valeurTemps,
      "Date_enregistrement": now,
      "ID_Bien": idBien,
      "Type_Bien": typeBien,
      "Type_Poste": "Equipement",
      "Type_Categorie": "Déplacements",
      "Sous_Categorie": "Véhicules",
      "Nom_Poste": nomEquipement,
      "Quantite": 1,
      "Unite": "unité",
      "Facteur_Emission": facteurEmission,
      "Emission_Calculee": facteurEmission / dureeAmortissement,
      "Mode_Calcul": "Amorti",
      "Annee_Achat": anneeAchat,
      "Duree_Amortissement": dureeAmortissement,
    };
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
