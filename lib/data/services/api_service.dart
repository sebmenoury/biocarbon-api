import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://biocarbon-api.onrender.com";

  static Future<List<Map<String, dynamic>>> getUCUsages() async {
    final response = await http.get(Uri.parse("$baseUrl/api/uc/usages"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur lors du chargement des usages");
    }
  }

  static Future<List<Map<String, dynamic>>> getUCEquipements() async {
    final response = await http.get(Uri.parse("$baseUrl/api/uc/equipements"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur lors du chargement des équipements");
    }
  }

  static Future<Map<String, Map<String, double>>> getEmissionsByType(
    String filtre,
  ) async {
    final usages = await getUCUsages();
    final equipements = await getUCEquipements();

    final records = switch (filtre) {
      "Equipements" => equipements,
      "Usages" => usages,
      _ => [...usages, ...equipements],
    };

    final Map<String, Map<String, double>> emissions = {};

    for (final record in records) {
      final categorie = record["Type_Categorie"] ?? "Autres";
      final sousCategorie = record["Sous_Categorie"] ?? "Inconnu";
      final emission =
          double.tryParse(record["Emission_Calculee"]?.toString() ?? "0") ?? 0;

      emissions.putIfAbsent(categorie, () => {});
      emissions[categorie]![sousCategorie] =
          (emissions[categorie]![sousCategorie] ?? 0) + emission;
    }

    return emissions;
  }
}
