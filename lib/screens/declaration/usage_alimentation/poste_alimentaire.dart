class PosteAlimentaire {
  final String nom;
  final double portion;
  final String unite;
  final double facteur;
  double? frequence;

  PosteAlimentaire({required this.nom, required this.portion, required this.unite, required this.facteur, this.frequence});
}
