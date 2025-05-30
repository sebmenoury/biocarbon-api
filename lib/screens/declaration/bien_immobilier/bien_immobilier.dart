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
}
