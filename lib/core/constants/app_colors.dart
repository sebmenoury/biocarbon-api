import 'package:flutter/material.dart';

class AppColors {
  static const Map<String, Color> categoryColors = {
    // Services publics (bruns/gris)
    "Admin. et défense": Color.fromARGB(255, 61, 51, 40),
    "Enseignement": Color.fromARGB(255, 112, 94, 77),
    "Santé": Color.fromARGB(255, 132, 118, 102),
    "Infrastructure": Color.fromARGB(255, 154, 140, 126),
    "Sport et Culture": Color.fromARGB(255, 173, 162, 150),
    "Autres publics": Color.fromARGB(255, 220, 216, 212),

    // Biens et services (verts)
    "Bricolage": Color.fromARGB(255, 24, 168, 41),
    "Eqt. Ménager": Color.fromARGB(255, 56, 179, 77),
    "Vêtements": Color.fromARGB(255, 82, 194, 96),
    "Digital": Color.fromARGB(255, 121, 204, 132),
    "Loisirs": Color.fromARGB(255, 156, 217, 164),
    "Assurance, Banque": Color.fromARGB(255, 189, 229, 193),

    // Déplacements (bleus)
    "Véhicules": Color.fromARGB(255, 1, 60, 110),
    "Voiture": Color.fromARGB(255, 5, 98, 176),
    "Train": Color.fromARGB(255, 38, 120, 193),
    "2-roues": Color.fromARGB(255, 110, 195, 229),
    "Car/Bus/Métro/tram": Color.fromARGB(255, 148, 208, 237),
    "Avion": Color.fromARGB(255, 179, 219, 239),
    "Autres": Color.fromARGB(255, 219, 231, 243),

    // Logement (violets/roses)
    "Construction": Color.fromARGB(255, 81, 2, 73),
    "Renov. Confort": Color.fromARGB(255, 134, 10, 129),
    "Eqt. Confort": Color.fromARGB(255, 152, 43, 147),
    "Gaz et fioul": Color.fromARGB(255, 184, 114, 184),
    "Électricité": Color.fromARGB(255, 203, 147, 202),
    "Déchets / Eau": Color.fromARGB(255, 219, 185, 218),

    // Alimentation (rouge > jaune clair)
    "Fruits et légumes": Color.fromARGB(255, 150, 38, 2),
    "Céréales et autres": Color.fromARGB(255, 229, 59, 4),
    "Laits et œufs": Color.fromARGB(255, 237, 100, 54),
    "Viande": Color.fromARGB(255, 235, 116, 74),
    "Poisson": Color.fromARGB(255, 240, 143, 111),
    "Boissons": Color.fromARGB(255, 243, 168, 145),
  };
}
