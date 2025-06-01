import '../eqt_bien_immobilier/poste_bien_immobilier.dart';

class BienImmobilier {
  String? idBien;
  String typeBien;
  String nomLogement;
  String? adresse;
  bool inclureDansBilan;
  int nbProprietaires; // 👈 ajouté ici
  PosteBienImmobilier poste;

  BienImmobilier({
    this.idBien,
    this.typeBien = "Logement principal",
    this.nomLogement = "Mon logement",
    this.adresse,
    this.inclureDansBilan = true,
    this.nbProprietaires = 1, // 👈 valeur par défaut
    PosteBienImmobilier? poste,
  }) : poste = poste ?? PosteBienImmobilier();

  factory BienImmobilier.fromMap(Map<String, dynamic> map) {
    return BienImmobilier(
      idBien: map['ID_Bien'],
      typeBien: map['Type_Bien'] ?? 'Logement principal',
      nomLogement: map['Dénomination'] ?? '',
      adresse: map['Adresse'] ?? '',
      inclureDansBilan: ['TRUE', true, 'true'].contains(map['Inclure_dans_Bilan']),
      nbProprietaires:
          map['Nb_Proprietaires'] is int
              ? map['Nb_Proprietaires']
              : int.tryParse(map['Nb_Proprietaires'].toString()) ?? 1,
      poste: PosteBienImmobilier(), // À adapter si tu veux aussi le charger
    );
  }

  Map<String, dynamic> toMap(String codeIndividu) {
    return {
      "ID_Bien": idBien,
      'Code_Individu': codeIndividu,
      'Type_Bien': typeBien,
      'Nb_Proprietaires': nbProprietaires,
      'Dénomination': nomLogement,
      'Adresse': adresse,
      'Inclure_dans_Bilan': inclureDansBilan ? 'TRUE' : 'FALSE',
    };
  }
}
