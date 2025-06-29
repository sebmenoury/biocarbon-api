// Classe temporaire pour l'écran Rénovation
class PosteTemp {
  final String nomPoste;
  final String sousCategorie;
  final double facteurEmission;
  final int duree;
  int quantite; // ici en m2
  int anneeAchat;
  String? idUsage; // ID existant (si présent dans UC-Poste)

  PosteTemp({required this.nomPoste, required this.sousCategorie, required this.facteurEmission, required this.duree, this.quantite = 0, required this.anneeAchat, this.idUsage});

  double get emissionAnnuelle {
    if (duree == 0 || quantite == 0) return 0.0;
    return (facteurEmission * quantite / duree).toDouble();
  }

  Map<String, dynamic> toJson({required String codeIndividu, required String typeTemps, required String valeurTemps, required String typeCategorie, required String idBien}) {
    return {
      "ID_Usage": idUsage,
      "Code_Individu": codeIndividu,
      "Type_Temps": typeTemps,
      "Valeur_Temps": valeurTemps,
      "Type_Categorie": typeCategorie,
      "Sous_Categorie": sousCategorie,
      "Nom_Usage": nomPoste,
      "Quantite": quantite,
      "Unite": "m2",
      "Annee_Achat": anneeAchat,
      "Facteur_Emission": facteurEmission,
      "Emission_Calculee": emissionAnnuelle,
      "Date_enregistrement": DateTime.now().toIso8601String(),
      "ID_Bien": idBien,
    };
  }
}
