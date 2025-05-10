import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://biocarbon-api.onrender.com";

  static Future<List<Map<String, dynamic>>> getUCUsages(
    String codeIndividu,
    String valeurTemps,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/uc/usages?code_individu=$codeIndividu&valeur_temps=$valeurTemps",
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur lors du chargement des usages");
    }
  }

  static Future<List<Map<String, dynamic>>> getUCEquipements(
    String codeIndividu,
    String valeurTemps,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/uc/equipements?code_individu=$codeIndividu&valeur_temps=$valeurTemps",
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur lors du chargement des équipements");
    }
  }

  static Future<Map<String, Map<String, double>>>
  getEmissionsByTypeAndYearAndUser(
    String filtre,
    String codeIndividu,
    String valeurTemps,
  ) async {
    List<Map<String, dynamic>> usages = [];
    List<Map<String, dynamic>> equipements = [];

    if (filtre == 'Usages' || filtre == 'Tous') {
      usages = await getUCUsages(codeIndividu, valeurTemps);
    }
    if (filtre == 'Equipements' || filtre == 'Tous') {
      equipements = await getUCEquipements(codeIndividu, valeurTemps);
    }

    final List<Map<String, dynamic>> allData = [...usages, ...equipements];
    final Map<String, Map<String, double>> result = {};

    for (final item in allData) {
      final String typeCategorie = item['Type_Categorie'] ?? 'Inconnu';
      final double emission =
          (item['Emission_Estimee'] ?? item['Emission_Calculee'] ?? 0)
              .toDouble();

      if (!result.containsKey(typeCategorie)) {
        result[typeCategorie] = {"total": 0};
      }
      result[typeCategorie]!["total"] =
          result[typeCategorie]!["total"]! + emission / 1000;
    }

    return result;
  }
}
