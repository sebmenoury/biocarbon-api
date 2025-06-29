class PosteRenovation {
  String nom;
  int annee;
  int quantite;
  double facteur;
  int duree;
  int nbProprietaires;
  String? idUsage;

  PosteRenovation({required this.nom, required this.annee, required this.quantite, required this.facteur, required this.duree, required this.nbProprietaires, this.idUsage});

  double get emissionCalculee {
    if (quantite == 0 || duree == 0 || nbProprietaires == 0) return 0;
    return quantite * facteur / duree / nbProprietaires;
  }
}
