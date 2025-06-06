class PosteBienImmobilier {
  String? id; // 👈 ajouté
  String nomEquipement; // "Maison Classique", "Appartement BBC", etc.
  String? typeBien; // "Logement principal", "Logement secondaire", etc.
  double surface;
  int anneeConstruction;
  int anneeGarage;
  int anneePiscine;
  int anneeAbri;

  bool garage;
  double surfaceGarage;

  bool piscine;
  String typePiscine;
  double surfacePiscine; // ✅ Nouveau champ (remplace longueur x largeur)

  bool abriEtSerre;
  double surfaceAbriEtSerre;

  PosteBienImmobilier({
    this.id, // 👈 ajouté
    this.nomEquipement = "",
    this.surface = 100,
    this.anneeConstruction = 2010,

    this.garage = false,
    this.surfaceGarage = 30,
    this.anneeGarage = 2010,

    this.piscine = false,
    this.typePiscine = "Piscine béton",
    this.surfacePiscine = 10, // ✅ Valeur par défaut
    this.anneePiscine = 2010,

    this.abriEtSerre = false,
    this.surfaceAbriEtSerre = 10,
    this.anneeAbri = 2010,
  });
}
