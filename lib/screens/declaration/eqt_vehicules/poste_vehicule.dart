import '../../../data/classes/poste_postes.dart';

class PosteVehicule {
  final String nomEquipement;
  int anneeAchat;
  final double facteurEmission;
  final int dureeAmortissement;
  final String? idBien;
  final String? typeBien;
  final String? nomLogement;
  final int nbProprietaires;
  String? idUsageInitial;

  int quantite; // 👈 AJOUT ICI
  final int? anneeAchatInitiale;

  PosteVehicule({
    required this.nomEquipement,
    required this.anneeAchat,
    required this.facteurEmission,
    required this.dureeAmortissement,
    required this.nbProprietaires,
    this.nomLogement,
    this.idBien,
    this.typeBien,
    this.quantite = 1, // 👈 Valeur par défaut
    this.idUsageInitial,
    this.anneeAchatInitiale, // ⚠️ ajouter ici
  });

  // 👇 Ajoute cette méthode pour permettre la duplication
  PosteVehicule.clone(PosteVehicule original)
    : nomEquipement = original.nomEquipement,
      anneeAchat = original.anneeAchat,
      facteurEmission = original.facteurEmission,
      dureeAmortissement = original.dureeAmortissement,
      quantite = original.quantite,
      nomLogement = original.nomLogement,
      nbProprietaires = original.nbProprietaires,
      idBien = original.idBien,
      typeBien = original.typeBien,
      idUsageInitial = null, // 👈 explicite
      anneeAchatInitiale = original.anneeAchatInitiale; // ⚠️ copier ici aussi

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

  String generateNewIdUsage() {
    final suffix = DateTime.now().millisecondsSinceEpoch; // sert uniquement à la création
    return "${idBien}_Véhicules_${nomEquipement}_${anneeAchat}_$suffix".replaceAll(' ', '_');
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
      "Nom_Logement": nomLogement,
      "Quantite": 1,
      "Unite": "unité",
      "Frequence": null, // Pas de fréquence pour les véhicules
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
