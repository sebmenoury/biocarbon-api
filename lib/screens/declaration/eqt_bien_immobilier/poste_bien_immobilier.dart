class PosteBienImmobilier {
  String nomEquipement; // "Maison Classique", "Appartement BBC", etc.
  double surface;
  int anneeConstruction;

  bool garage;
  double surfaceGarage;

  bool piscine;
  String typePiscine;
  double surfacePiscine; // ✅ Nouveau champ (remplace longueur x largeur)

  bool abriEtSerre;
  double surfaceAbriEtSerre;

  PosteBienImmobilier({
    this.nomEquipement = "",
    this.surface = 100,
    this.anneeConstruction = 2010,

    this.garage = false,
    this.surfaceGarage = 30,

    this.piscine = false,
    this.typePiscine = "Piscine béton",
    this.surfacePiscine = 10, // ✅ Valeur par défaut

    this.abriEtSerre = false,
    this.surfaceAbriEtSerre = 10,
  });
}
