import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = "https://biocarbon-api.onrender.com";
  const codeIndividu = "BASILE";
  const valeurTemps = "2025";

  final response = await http.get(
    Uri.parse(
      "$baseUrl/api/uc/postes?code_individu=$codeIndividu&valeur_temps=$valeurTemps",
    ),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    print("🔎 Lignes 'Logement' :");

    for (final item in data) {
      final categorie = item["Type_Categorie"] ?? "Inconnu";

      if (categorie == "Logement") {
        final nom = item["Nom_Poste"] ?? "??";
        final poste = item["Type_Poste"] ?? "?";
      }
    }
  } else {
    print("Erreur API : ${response.statusCode}");
  }
}
