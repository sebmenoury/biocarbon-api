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
  'Equipements Multi-média': 'Mes équipements multi-média par logement',
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
      "🛋️ Ces équipements sont amortis annuellement en fonction de leur durée de vie. "
      "Le calcul tient compte de leur énergie grise de fabrication et du nombre de propriétaires du logement associé.",

  'Construction':
      "🧱 On retrouve ici l'amortissement de l'énergie grise qui a été nécessaire à la construction (ou aux travaux de rénovation) des biens concernés.\n"
      "💡 Ces émissions sont calculées selon la formule suivante par type de logement :\n"
      "Émissions énergie grise constrution (/m²) \n"
      "× Surface du bien (en m²) \n  "
      "× Facteur de pondération (période de construction), \n "
      "/ Nombre de propriétaires",

  'Electricité': "🔌 Vous déclarez ici la consommation annuelle d’électricité par logement, qui est répartie entre les co-propriétaires.",
};

/// Référentiel des images explicatives par sous-catégorie
const Map<String, String> imageParSousCategorie = {
  'Construction': 'assets/images/emission_construction.png',
  // Ajoute d’autres cas si besoin
};
