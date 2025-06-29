/// Référentiel des titres par sous-catégorie
const Map<String, String> titreParSousCategorie = {
  'Déplacements Voiture': 'Mes déplacements voiture',
  'Déplacements Train/Métro/Bus': 'Mes déplacements train/métro/bus',
  'Déplacements Avion': 'Mes déplacements avion',
  'Déplacements Autres': 'Mes autres déplacements',
  'Gaz et Fioul': 'Ma consommation gaz / fioul par logement',
  'Véhicules': 'Mes véhicules personnels par logement',
  'Biens Immobiliers': 'Mes biens immobiliers',
  'Alimentation': 'Mon alimentation',
  'Construction': 'L’empreinte construction par logement',
  'Equipements Confort': 'Mes équipements de confort par logement',
  'Equipements Ménager': 'Mes équipements ménagers par logement',
  'Equipements Bricolage': 'Mes équipements de bricolage par logement',
  'Equipements Multi-media': 'Mes équipements multi-média par logement',
  'Habillement': 'Mes vêtements et accessoires',
  'Loisirs': 'Mes loisirs',
  'Banque et assurances': 'Mes banques et assurances',
  'Déchets et Eau': 'Ma consommation d’eau et de déchets par logement',
  'Services publics': 'Les services publics qui me sont attribués',
  'Electricité': 'Ma consommation d’électricité par logement',
};

/// Référentiel des textes explicatifs par sous-catégorie
const Map<String, String> texteParSousCategorie = {
  'Equipements Confort':
      "❄️ Ces équipements sont amortis annuellement en fonction de leur durée de vie. "
      "La date d'achat (considérée comme la date de construction) est importante pour la projection de l'amortissement dans le temps. "
      "Le calcul tient compte de leur énergie grise de fabrication et du nombre de propriétaires du logement associé.",

  'Equipements Ménager':
      "🍽️ Ces équipements sont amortis annuellement en fonction de leur durée de vie. "
      "La date d'achat est importante pour la projection de l'amortissement dans le temps. "
      "Le calcul tient compte de leur énergie grise de fabrication et du nombre de propriétaires du logement associé.",

  'Equipements Bricolage':
      "🛠️ Ces équipements sont amortis annuellement en fonction de leur durée de vie. "
      "La date d'achat est importante pour la projection de l'amortissement dans le temps. "
      "Le calcul tient compte de leur énergie grise de fabrication et du nombre de propriétaires du logement associé.",

  'Equipements Multi-media':
      "📺 Ces équipements sont amortis annuellement en fonction de leur durée de vie. "
      "La date d'achat est importante pour la projection de l'amortissement dans le temps. "
      "Le calcul tient compte de leur énergie grise de fabrication et du nombre de propriétaires du logement associé.",

  'Véhicules':
      "🚗 Les véhicules personnels représentent un poste d’émission majeur, lié à leur fabrication (énergie grise) et à leur usage quotidien.\n\n"
      "Dans cette section, tu peux déclarer les voitures, deux-roues motorisés, vélos et autres moyens de transport personnels.",

  'Electricité': "🔌 Vous déclarez ici la consommation annuelle d’électricité par logement, qui est répartie entre le nombre d'habitants.",
};

/// Référentiel des images explicatives par sous-catégorie
const Map<String, String> imageParSousCategorie = {
  'Construction': 'assets/images/emission_construction.png',
  // Ajoute d’autres cas si besoin
};
