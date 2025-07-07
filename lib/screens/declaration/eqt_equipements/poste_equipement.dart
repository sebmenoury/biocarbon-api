class PosteEquipement {
  final String nomEquipement;
  int anneeAchat;
  final double facteurEmission;
  final int dureeAmortissement;
  final String? idBien;
  final String? typeBien;
  final String? nomLogement;
  final int nbProprietaires;
  String? idUsageInitial;

  int quantite;
  final int? anneeAchatInitiale;

  PosteEquipement({
    required this.nomEquipement,
    required this.anneeAchat,
    required this.facteurEmission,
    required this.dureeAmortissement,
    required this.nbProprietaires,
    this.nomLogement,
    this.idBien,
    this.typeBien,
    this.quantite = 1,
    this.idUsageInitial,
    this.anneeAchatInitiale,
  });

  PosteEquipement.clone(PosteEquipement original)
    : nomEquipement = original.nomEquipement,
      anneeAchat = original.anneeAchat,
      facteurEmission = original.facteurEmission,
      dureeAmortissement = original.dureeAmortissement,
      quantite = original.quantite,
      nomLogement = original.nomLogement,
      nbProprietaires = original.nbProprietaires,
      idBien = original.idBien,
      typeBien = original.typeBien,
      idUsageInitial = null,
      anneeAchatInitiale = original.anneeAchatInitiale;

  /// Génère un ID usage unique basé sur timestamp
  String generateNewIdUsage(String sousCategorie) {
    final suffix = DateTime.now().millisecondsSinceEpoch;
    return "TEMP_${idBien}_${sousCategorie}_${nomEquipement}_${anneeAchat}_$suffix".replaceAll(' ', '_');
  }

  /// Conversion en map pour envoi à l’API
  Map<String, dynamic> toMap({required String codeIndividu, required String typeTemps, required String valeurTemps, required String sousCategorie}) {
    final now = DateTime.now().toIso8601String();
    final idUsage = generateNewIdUsage(sousCategorie);

    return {
      "ID_Usage": idUsage,
      "Code_Individu": codeIndividu,
      "Type_Temps": typeTemps,
      "Valeur_Temps": valeurTemps,
      "Date_enregistrement": now,
      "ID_Bien": idBien,
      "Type_Bien": typeBien,
      "Type_Poste": "Equipement",
      "Type_Categorie": "Biens",
      "Sous_Categorie": sousCategorie,
      "Nom_Poste": nomEquipement,
      "Nom_Logement": nomLogement,
      "Quantite": quantite,
      "Unite": "unité",
      "Frequence": null,
      "Nb_Personne": nbProprietaires.toDouble(), // Nombre de propriétaires
      "Facteur_Emission": facteurEmission,
      "Emission_Calculee": (quantite * facteurEmission) / dureeAmortissement,
      "Mode_Calcul": "Amorti",
      "Annee_Achat": anneeAchat,
      "Duree_Amortissement": dureeAmortissement,
    };
  }
}
