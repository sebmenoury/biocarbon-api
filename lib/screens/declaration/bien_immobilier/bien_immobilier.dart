import '../eqt_bien_immobilier/poste_bien_immobilier.dart';

class BienImmobilier {
  String? idBien;
  String typeBien;
  String nomLogement;
  String? adresse;
  bool inclureDansBilan;
  PosteBienImmobilier poste;

  BienImmobilier({
    this.idBien,
    this.typeBien = "Logement principal",
    this.nomLogement = "Mon logement",
    this.adresse,
    this.inclureDansBilan = true,
    PosteBienImmobilier? poste,
  }) : poste = poste ?? PosteBienImmobilier();
}
