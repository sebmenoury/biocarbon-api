import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://biocarbon-api.onrender.com";

  static Future<List<Map<String, dynamic>>> getUCPostes(
    String codeIndividu,
    String valeurTemps,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/uc/postes?code_individu=$codeIndividu&valeur_temps=$valeurTemps",
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur lors du chargement des postes");
    }
  }

  static Future<Map<String, Map<String, double>>>
  getEmissionsByTypeAndYearAndUser(
    String filtre, // 'Tous', 'Usages', 'Equipements'
    String codeIndividu,
    String valeurTemps,
  ) async {
    List<Map<String, dynamic>> allData = await getUCPostes(
      codeIndividu,
      valeurTemps,
    );

    if (filtre != 'Tous') {
      allData = allData.where((item) => item['Type_Poste'] == filtre).toList();
    }

    final Map<String, Map<String, double>> result = {};

    for (final item in allData) {
      final String typeCategorie = item['Type_Categorie'] ?? 'Inconnu';
      final emission = (item['Emission_Calculee'] ?? 0).toDouble();

      if (!result.containsKey(typeCategorie)) {
        result[typeCategorie] = {"total": 0};
      }
      result[typeCategorie]!["total"] =
          result[typeCategorie]!["total"]! + emission / 1000;
    }

    return result;
  }

  static Future<Map<String, Map<String, double>>>
  getEmissionsByCategoryAndSousCategorie(
    String codeIndividu,
    String valeurTemps,
  ) async {
    final List<Map<String, dynamic>> allData = await getUCPostes(
      codeIndividu,
      valeurTemps,
    );

    final Map<String, Map<String, double>> result = {};

    for (final item in allData) {
      final String typeCategorie = item['Type_Categorie'] ?? 'Inconnu';
      final String sousCategorie = item['Sous_Categorie'] ?? 'Autre';
      final emission = (item['Emission_Calculee'] ?? 0).toDouble();

      result.putIfAbsent(typeCategorie, () => {});
      result[typeCategorie]![sousCategorie] =
          (result[typeCategorie]![sousCategorie] ?? 0) + emission / 1000;
    }

    return result;
  }

  static Future<Map<String, Map<String, double>>>
  getEmissionsFilteredByTypePosteGroupedByCategorie(
    String typePoste, // "Usage", "Equipement"
    String codeIndividu,
    String valeurTemps,
  ) async {
    final allData = await getUCPostes(codeIndividu, valeurTemps);

    // Filtrer par Type_Poste
    final filtered =
        allData.where((item) => item['Type_Poste'] == typePoste).toList();

    final Map<String, Map<String, double>> result = {};

    for (final item in filtered) {
      final categorie = item['Type_Categorie'] ?? 'Inconnu';
      final emission = (item['Emission_Calculee'] ?? 0).toDouble();

      result.putIfAbsent(categorie, () => {});
      result[categorie]!['total'] =
          (result[categorie]!['total'] ?? 0) + emission / 1000;
    }

    return result;
  }
}
