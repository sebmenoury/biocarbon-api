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
    'Logement': ["Construction", "Equipements Confort", "Gaz et Fioul", "Électricité", "Déchets et Eau"],
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
      "Poisson",
      "Laits et œufs",
      "Viande",
      "Plats cuisinés"
          "Boissons",
    ],
    'Biens et services': [
      "Equipements Bricolage",
      "Equipements Ménager",
      "Habillement",
      "Equipements Multi-média",
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
