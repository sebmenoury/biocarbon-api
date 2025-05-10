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
      final double emission = (item['Emission_Calculee'] ?? 0).toDouble();

      if (!result.containsKey(typeCategorie)) {
        result[typeCategorie] = {"total": 0};
      }
      result[typeCategorie]!["total"] =
          result[typeCategorie]!["total"]! + emission / 1000;
    }

    return result;
  }
}
