import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, Map<String, double>>> fetchEmissionData() async {
  final url = Uri.parse(
    "http://127.0.0.1:5000/synthese?individu=BASILE&annee=2025",
  );
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    final Map<String, Map<String, double>> grouped = {};
    for (var item in data) {
      final type = item["Type_Categorie"];
      final sous = item["Sous_Categorie"];
      final value = (item["Emissions_CO2_kg"] as num).toDouble() / 1000;
      grouped[type] ??= {};
      grouped[type]![sous] = value;
    }
    return grouped;
  } else {
    throw Exception("Erreur API");
  }
}
