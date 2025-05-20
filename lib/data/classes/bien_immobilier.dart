import 'poste_bien_immobilier.dart';

class BienImmobilier {
  final String? idBien;
  String typeBien; // "Maison principale", "Maison secondaire", "Appartement locatif"
  String nomLogement;
  String? adresse;
  bool inclureDansBilan;

  PosteBienImmobilier poste; // 🔁 association directe avec le descriptif technique

  BienImmobilier({
    this.idBien,
    this.typeBien = "Maison principale",
    this.nomLogement = "Mon logement",
    this.adresse,
    this.inclureDansBilan = true,
    required this.poste, // 👈 il devient obligatoire ici
  });
}
