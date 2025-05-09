class AppOrder {
  // Ordre fixe des types de catégorie
  static const List<String> typeCategoryOrder = [
    'Logement',
    'Déplacements',
    'Alimentation',
    'Biens et services',
    'Services publics',
  ];

  // Ordre des sous-catégories par type (du plus foncé au plus clair)
  static const Map<String, List<String>> sousCategorieOrder = {
    'Logement': [
      "Construction",
      "Renov. Confort",
      "Eqt. Confort",
      "Gaz et fioul",
      "Électricité",
      "Déchets / Eau",
    ],
    'Déplacements': [
      "Véhicules",
      "Voiture",
      "Train",
      "2-roues",
      "Car/Bus/Métro/tram",
      "Avion",
      "Autres",
    ],
    'Alimentation': [
      "Fruits et légumes",
      "Céréales et autres",
      "Laits et œufs",
      "Viande",
      "Poisson",
      "Boissons",
    ],
    'Biens et services': [
      "Bricolage",
      "Eqt. Ménager",
      "Vêtements",
      "Digital",
      "Loisirs",
      "Assurance, Banque",
    ],
    'Services publics': [
      "Admin. et défense",
      "Enseignement",
      "Santé",
      "Infrastructure",
      "Sport et Culture",
      "Autres publics",
    ],
  };
}
