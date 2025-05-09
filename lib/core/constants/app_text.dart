class AppText {
  // Transcodage des Type_Categorie en libellés abrégés pour les graphes
  static const Map<String, String> shortCategoryLabels = {
    'Services publics': 'Serv. Pub.',
    'Biens et services': 'Biens & S.',
    'Alimentation': 'Alimentation',
    'Logement': 'Logement',
    'Déplacements': 'Dépl.',
  };

  /// Méthode utilitaire pour récupérer le label abrégé
  static String shortLabel(String fullLabel) {
    return shortCategoryLabels[fullLabel] ?? fullLabel;
  }
}
