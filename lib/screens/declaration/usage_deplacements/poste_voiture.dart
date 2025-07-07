class PosteVoiture {
  String nomUsage;
  double valeur;
  String unite;
  double facteurEmission;
  double consoL100; // 🆕 consommation en L/100km
  double personnes; // 🆕 nombre de personnes à bord
  String? idUsageInitial;
  int nbHabitants; // si encore utilisé ailleurs

  PosteVoiture({
    required this.nomUsage,
    required this.valeur,
    required this.unite,
    required this.facteurEmission,
    this.idUsageInitial,
    this.consoL100 = 6.0, // valeur par défaut
    this.personnes = 1.0, // valeur par défaut
    this.nbHabitants = 1, // valeur par défaut
  });

  double calculerEmissionVoiture() {
    // 🧮 Émission = (km * conso * facteur) / personnes
    if (valeur == 0 || consoL100 == 0 || facteurEmission == 0) return 0;
    return (valeur * consoL100 / 100 * facteurEmission) / (personnes > 0 ? personnes : 1);
  }
}
