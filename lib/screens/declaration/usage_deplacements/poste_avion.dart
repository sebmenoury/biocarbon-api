class PosteAvion {
  final String? idUsage;
  final String? codeIndividu;
  final String? typeCategorie;
  final String? sousCategorie;
  final String? nomPoste;
  final double? distanceKm;
  final int? frequence;
  final double? facteurEmission;
  final double? emissionCalculee;
  final String? date;
  final String? unite;

  PosteAvion({
    this.idUsage,
    this.codeIndividu,
    this.typeCategorie,
    this.sousCategorie,
    this.nomPoste,
    this.distanceKm,
    this.frequence,
    this.facteurEmission,
    this.emissionCalculee,
    this.date,
    this.unite = "km",
  });

  factory PosteAvion.fromJson(Map<String, dynamic> json) {
    return PosteAvion(
      idUsage: json['ID_Usage'],
      codeIndividu: json['Code_Individu'],
      typeCategorie: json['Type_Categorie'],
      sousCategorie: json['Sous_Categorie'],
      nomPoste: json['Nom_Poste'],
      distanceKm: double.tryParse(json['Quantite'].toString()),
      frequence: int.tryParse(json['Quantite'].toString()),
      facteurEmission: double.tryParse(json['Facteur_Emission'].toString()),
      emissionCalculee: double.tryParse(json['Emission_Calculee'].toString()),
      date: json['Date_enregistrement'],
      unite: json['Unite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "ID_Usage": idUsage,
      "Code_Individu": codeIndividu,
      "Type_Categorie": typeCategorie,
      "Sous_Categorie": sousCategorie,
      "Nom_Poste": nomPoste,
      "Distance_km": distanceKm,
      "Frequence": frequence,
      "Facteur_Emission": facteurEmission,
      "Emission_Calculee": emissionCalculee,
      "Date_enregistrement": date,
      "Unite": unite,
      // Ajoute d'autres champs si nécessaires
    };
  }
}
