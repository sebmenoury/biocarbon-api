import '../eqt_bien_immobilier/poste_bien_immobilier.dart';

class BienImmobilier {
  final String? idBien;
  String typeBien; // "Logement principal", "Logement secondair", "Bien locatif"
  String nomLogement;
  String? adresse;
  bool inclureDansBilan;

  PosteBienImmobilier poste; // 🔁 association directe avec le descriptif technique

  BienImmobilier({
    this.idBien,
    this.typeBien = "Logement principal",
    this.nomLogement = "Mon logement",
    this.adresse,
    this.inclureDansBilan = true,
    required this.poste, // 👈 il devient obligatoire ici
  });
}
