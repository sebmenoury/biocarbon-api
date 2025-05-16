class Poste {
  final String idUsage;
  final String typeCategorie;
  final String sousCategorie;
  final String typePoste;
  final String? nomPoste;
  final String? idBien;
  final String? typeBien;
  final double quantite;
  final String unite;
  final double emissionCalculee;
  final String? frequence;
  final int? anneeAchat;
  final int? dureeAmortissement;

  Poste({
    required this.idUsage,
    required this.typeCategorie,
    required this.sousCategorie,
    required this.typePoste,
    this.nomPoste,
    this.idBien,
    this.typeBien,
    required this.quantite,
    required this.unite,
    required this.emissionCalculee,
    this.frequence,
    this.anneeAchat,
    this.dureeAmortissement,
  });

  factory Poste.fromJson(Map<String, dynamic> json) {
    return Poste(
      idUsage:
          json['ID_Usage']?.toString() ?? '', // 🔹 ID attendu dans UC-Poste
      typeCategorie: json['Type_Categorie'] ?? '',
      sousCategorie: json['Sous_Categorie'] ?? '',
      typePoste: json['Type_Poste'] ?? '',
      nomPoste: json['Nom_Poste'],
      idBien: json['ID_Bien'],
      typeBien: json['Type_Bien'],
      quantite: double.tryParse(json['Quantite'].toString()) ?? 0.0,
      unite: json['Unite'] ?? '',
      emissionCalculee:
          double.tryParse(json['Emission_Calculee'].toString()) ?? 0.0,
      frequence: json['Facteur_Emission']?.toString(),
      anneeAchat: int.tryParse(json['Annee_Achat'].toString()),
      dureeAmortissement: int.tryParse(json['Duree_Amortissement'].toString()),
    );
  }
}
