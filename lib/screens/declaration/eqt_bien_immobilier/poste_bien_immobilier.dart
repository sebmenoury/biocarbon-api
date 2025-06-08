class PosteBienImmobilier {
  String? id; // 👈 ajouté
  String nomEquipement; // "Maison Classique", "Appartement BBC", etc.
  String? nomLogement; // Nom du logement, par exemple "Mon appartement"
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
    this.anneeConstruction = 2025,

    this.garage = false,
    this.surfaceGarage = 0,
    this.anneeGarage = 2025,

    this.piscine = false,
    this.typePiscine = "",
    this.surfacePiscine = 0, // ✅ Valeur par défaut
    this.anneePiscine = 2025,

    this.abriEtSerre = false,
    this.surfaceAbriEtSerre = 0,
    this.anneeAbri = 2025,
  });
}
