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

    print("📦 Emission_Calculee brut depuis l'API UC-Postes :");
    for (final item in data) {
      final id = item["ID_Usage"] ?? "??";
      final nom = item["Nom_Poste"] ?? "??";
      final emission = item["Emission_Calculee"];
      print("- [$id] $nom → Emission_Calculee = '$emission'");
    }
  } else {
    print("❌ Erreur API : ${response.statusCode}");
  }
}
