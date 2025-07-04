class PosteUsage {
  final String nomUsage;
  double valeur; // ex: kWh
  final double facteurEmission;
  final String? unite;
  final String? idUsageInitial;
  final String? idBien;
  final String? typeBien;
  final String? nomLogement;
  final double nbHabitants;

  PosteUsage({required this.nomUsage, required this.valeur, required this.facteurEmission, this.idBien, this.nomLogement, this.nbHabitants = 1.0, this.typeBien, this.unite, this.idUsageInitial});

  /// Génère un ID temporaire unique
  String generateNewIdUsage(String sousCategorie) {
    final suffix = DateTime.now().millisecondsSinceEpoch;
    return "TEMP_${sousCategorie}_${nomUsage}_$suffix".replaceAll(' ', '_');
  }

  /// Calcule l’émission totale (valeur × facteur / nbHabitants)
  double calculerEmission(double nbHabitants) {
    final e = (valeur * facteurEmission) / nbHabitants;
    return e.isNaN ? 0 : e;
  }

  double calculerEmissionLoisir() {
    final e = (valeur * facteurEmission);
    return e.isNaN ? 0 : e;
  }

  /// Conversion pour envoi à l’API
  Map<String, dynamic> toMap({required String codeIndividu, required String typeTemps, required String valeurTemps, required String sousCategorie, required double nbHabitants}) {
    final now = DateTime.now().toIso8601String();
    final idUsage = generateNewIdUsage(sousCategorie);

    return {
      "ID_Usage": idUsage,
      "Code_Individu": codeIndividu,
      "Type_Temps": typeTemps,
      "Valeur_Temps": valeurTemps,
      "Date_enregistrement": now,
      "ID_Bien": null,
      "Type_Bien": null,
      "Type_Poste": "Usage",
      "Type_Categorie": "Logement",
      "Sous_Categorie": sousCategorie,
      "Nom_Poste": nomUsage,
      "Nom_Logement": null,
      "Quantite": valeur,
      "Unite": unite ?? "kWh",
      "Frequence": null,
      "Facteur_Emission": facteurEmission,
      "Emission_Calculee": calculerEmission(nbHabitants),
      "Mode_Calcul": "Direct",
    };
  }
}
