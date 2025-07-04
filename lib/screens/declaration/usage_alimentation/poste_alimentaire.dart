class PosteAlimentaire {
  final String nom;
  final double portion;
  final String unite;
  final double? facteur;
  final String sousCategorie;
  double? frequence;

  PosteAlimentaire({required this.nom, required this.portion, required this.unite, required this.facteur, this.frequence, required this.sousCategorie});
  factory PosteAlimentaire.fromJson(Map<String, dynamic> json) {
    return PosteAlimentaire(
      nom: json['Nom_Poste'],
      portion: double.tryParse(json['Quantite'].toString()) ?? 0.0,
      sousCategorie: json['Sous_Categorie'] ?? '',

      unite: json['Unite'] ?? '',

      frequence: double.tryParse(json['Frequence']?.toString() ?? ''),
      facteur: double.tryParse(json['Facteur_Emission']?.toString() ?? ''),
    );
  }
}
