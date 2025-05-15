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
      "Biens Immobiliers",
      "Equipements Confort",
      "Gaz et fioul",
      "Électricité",
      "Déchets / Eau",
    ],
    'Déplacements': [
      "Véhicules",
      "Déplacements Voiture",
      "Déplacements Train/Métro/Bus",
      "Déplacements Avion",
      "Déplacements Autres",
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
      "Equipement Bricolage",
      "Equipement Ménager",
      "Habillement",
      "Equipement Multi-media",
      "Loisirs",
      "Banques et assurances",
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
