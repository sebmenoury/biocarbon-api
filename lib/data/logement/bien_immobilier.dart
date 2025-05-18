class BienImmobilier {
  final String? idBien;
  String nomLogement; // Nom personnalisé par l'utilisateur
  String nomEquipement;
  String type; // ex : "Maison Classique", "Appartement"
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

  BienImmobilier({
    this.idBien,
    this.nomLogement = "Mon logement",
    this.nomEquipement = "",
    required this.type,
    this.surface = 100,
    this.anneeConstruction = 2010,
    this.nbProprietaires = 1,
    this.surfaceGarage = 30,
    this.garage = false,
    this.piscine = false,
    this.typePiscine = "Piscine béton",
    this.piscineLongueur = 4,
    this.piscineLargeur = 2.5,
    this.abriEtSerre = false,
    this.surfaceAbriEtSerre = 10,
  });
}
