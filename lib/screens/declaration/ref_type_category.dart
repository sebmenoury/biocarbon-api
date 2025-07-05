final Map<String, String> refTypeCategorie = {
  // Équipements
  "Biens Immobiliers": "Logement",
  "Construction": "Logement",
  "Rénovation": "Logement",
  "Equipements Confort": "Logement",
  "Equipements Ménager": "Biens et services",
  "Equipements Bricolage": "Biens et services",
  "Equipements Multi-media": "Biens et services",
  "Véhicules": "Déplacements",

  // Usages
  "Electricité": "Logement",
  "Gaz et Fioul": "Logement",
  "Déchets et Eau": "Logement",
  "Alimentation": "Alimentation",
  "Loisirs": "Biens et services",
  "Habillement": "Biens et services",
  "Banques et Assurances": "Biens et services",
  "Déplacements Avion": "Déplacements",
  "Déplacements Voiture": "Déplacements",
  "Déplacements Train/Métro/Bus": "Déplacements",
  "Déplacements Autres": "Déplacements",
  "Services publics": "Services publics",
};

String? getTypeCategorieFromLabel(String label) {
  return refTypeCategorie[label];
}
