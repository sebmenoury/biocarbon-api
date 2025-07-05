class Poste {
  final String idUsage;
  final String codeIndividu;
  final String typeTemps;
  final String valeurTemps;
  final String dateEnregistrement;
  final String typeCategorie;
  final String sousCategorie;
  final String typePoste;
  final String? nomPoste;
  final String? idBien;
  final String? typeBien;
  final String? nomLogement;
  final double quantite;
  final String unite;
  final double? facteurEmission;
  final double emissionCalculee;
  final String? frequence;
  final int? anneeAchat;
  final int? dureeAmortissement;
  final String? modeCalcul;

  Poste({
    required this.idUsage,
    required this.codeIndividu,
    required this.typeTemps,
    required this.valeurTemps,
    required this.dateEnregistrement,
    required this.typeCategorie,
    required this.sousCategorie,
    required this.typePoste,
    this.nomPoste,
    this.idBien,
    this.typeBien,
    this.nomLogement,
    required this.quantite,
    required this.unite,
    this.facteurEmission,
    required this.emissionCalculee,
    this.frequence,
    this.anneeAchat,
    this.dureeAmortissement,
    this.modeCalcul,
  });

  factory Poste.fromJson(Map<String, dynamic> json) {
    return Poste(
      idUsage: json['ID_Usage']?.toString() ?? '',
      codeIndividu: json['Code_Individu'] ?? '',
      typeTemps: json['Type_Temps'] ?? '',
      valeurTemps: (json['Valeur_Temps'] ?? '').toString(),
      dateEnregistrement: json['Date_enregistrement'] ?? '',
      typeCategorie: json['Type_Categorie'] ?? '',
      sousCategorie: json['Sous_Categorie'] ?? '',
      typePoste: json['Type_Poste'] ?? '',
      nomPoste: json['Nom_Poste'],
      idBien: json['ID_Bien'],
      typeBien: json['Type_Bien'],
      nomLogement: json['Nom_Logement'],
      quantite: double.tryParse(json['Quantite'].toString()) ?? 0.0,
      unite: json['Unite'] ?? '',
      facteurEmission: double.tryParse(json['Facteur_Emission']?.toString() ?? ''),
      emissionCalculee: double.tryParse(json['Emission_Calculee'].toString()) ?? 0.0,
      frequence: json['Frequence']?.toString(),
      anneeAchat: int.tryParse(json['Annee_Achat']?.toString() ?? ''),
      dureeAmortissement: int.tryParse(json['Duree_Amortissement']?.toString() ?? ''),
      modeCalcul: json['Mode_Calcul'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_Usage': idUsage,
      'Code_Individu': codeIndividu,
      'Type_Temps': typeTemps,
      'Valeur_Temps': valeurTemps,
      'Date_enregistrement': dateEnregistrement,
      'ID_Bien': idBien ?? '',
      'Type_Bien': typeBien ?? '',
      'Type_Poste': typePoste,
      'Type_Categorie': typeCategorie,
      'Sous_Categorie': sousCategorie,
      'Nom_Poste': nomPoste ?? '',
      'Nom_Logement': nomLogement ?? '',
      'Quantite': quantite,
      'Unite': unite,
      'Frequence': frequence ?? '',
      'Facteur_Emission': facteurEmission ?? 0.0,
      'Emission_Calculee': emissionCalculee,
      'Mode_Calcul': modeCalcul ?? '',
      'Annee_Achat': anneeAchat,
      'Duree_Amortissement': dureeAmortissement,
    };
  }
}
