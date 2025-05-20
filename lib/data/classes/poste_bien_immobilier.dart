class PosteBienImmobilier {
  String nomEquipement; // "Maison Classique", "Appartement BBC", etc.
  double surface;
  int anneeConstruction;
  int nbProprietaires;

  bool garage;
  double surfaceGarage;

  bool piscine;
  String typePiscine;
  double piscineLongueur;
  double piscineLargeur;

  bool abriEtSerre;
  double surfaceAbriEtSerre;

  PosteBienImmobilier({
    this.nomEquipement = "",
    this.surface = 100,
    this.anneeConstruction = 2010,
    this.nbProprietaires = 1,
    this.garage = false,
    this.surfaceGarage = 30,
    this.piscine = false,
    this.typePiscine = "Piscine béton",
    this.piscineLongueur = 4,
    this.piscineLargeur = 2.5,
    this.abriEtSerre = false,
    this.surfaceAbriEtSerre = 10,
  });
}
