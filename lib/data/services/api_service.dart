import 'dart:convert';
import 'package:http/http.dart' as http;
import '../classes/poste_postes.dart';

class ApiService {
  static const String baseUrl = "https://biocarbon-api.onrender.com";

  // ---------------------------------------------------------------------------
  // 🔧 MÉTHODE UTILITAIRE COMMUNE
  // ---------------------------------------------------------------------------

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur API : ${response.statusCode} - ${response.body}');
    }
  }

  // ---------------------------------------------------------------------------
  // 📚 REF - DONNES DE REFERENCE
  // ---------------------------------------------------------------------------
  // récupère les émissions par équipements
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getRefEquipements() async {
    final response = await http.get(Uri.parse("$baseUrl/api/ref/equipements"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur lors du chargement des équipements");
    }
  }
  // REF - Usages
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getRefUsages() async {
    final response = await http.get(Uri.parse('$baseUrl/api/ref/usages'));
    return _handleResponse(response);
  }

  // REF - Alimentation
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getRefAlimentation() async {
    final response = await http.get(Uri.parse('$baseUrl/api/ref/alimentation'));
    return _handleResponse(response);
  }

  // REF - Aéroports
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getRefPays() async {
    final response = await http.get(Uri.parse('$baseUrl/api/ref/aeroports/pays'));
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getRefVilles(String pays) async {
    final response = await http.get(Uri.parse('$baseUrl/api/ref/aeroports/villes?pays=$pays'));
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getRefAeroports(String pays, String ville) async {
    final response = await http.get(Uri.parse('$baseUrl/api/ref/aeroports/noms?pays=$pays&ville=$ville'));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getRefAeroportDetails(String pays, String ville, String aeroport) async {
    final response = await http.get(Uri.parse('$baseUrl/api/ref/aeroports/details?pays=$pays&ville=$ville&aeroport=$aeroport'));
    return _handleResponse(response);
  }
  // ---------------------------------------------------------------------------
  // 📦 UC - BIENS IMMOBILIERS
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getBiens(String codeIndividu) async {
    final response = await http.get(Uri.parse('$baseUrl/api/uc/biens?code_individu=$codeIndividu'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Erreur lors du chargement des biens");
    }
  }

  static Future<Map<String, dynamic>> getBienActif() async {
    final tousLesBiens = await getBiens("BASILE"); // ou un autre filtre
    return tousLesBiens.isNotEmpty ? tousLesBiens.first : {};
  }

  static Future<Map<String, dynamic>> addBien({
    required String idBien, // 👈 ajouter cet argument
    required String codeIndividu,
    required String typeBien,
    required String description,
    required String adresse,
    required int nbProprietaires,
    required String nbHabitants,
    required String inclureDansBilan,
  }) async {
    print("📤 Envoi de données à l'API addBien :");
    print(
      jsonEncode({
        'ID_Bien': idBien,
        'Code_Individu': codeIndividu,
        'Type_Bien': typeBien,
        'Dénomination': description,
        'Adresse': adresse,
        'Nb_Proprietaires': nbProprietaires,
        'Nb_Habitants': nbHabitants,
        'Inclure_dans_bilan': inclureDansBilan,
      }),
    );
    final response = await http.post(
      Uri.parse('$baseUrl/api/uc/biens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ID_Bien': idBien, // 👈 important !
        'Code_Individu': codeIndividu,
        'Type_Bien': typeBien,
        'Dénomination': description,
        'Adresse': adresse,
        'Nb_Proprietaires': nbProprietaires,
        'Nb_Habitants': nbHabitants,
        'Inclure_dans_bilan': inclureDansBilan,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateBien(String idBien, Map<String, dynamic> data) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/uc/biens/$idBien'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteBien(String idBien) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/uc/biens/$idBien'));
    return _handleResponse(response);
  }

  // ---------------------------------------------------------------------------
  // 📦 UC - POSTES en écriture
  // ---------------------------------------------------------------------------
  // 📥 Ajouter un poste
  static Future<Map<String, dynamic>> addUCPoste(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl/api/uc/postes'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return _handleResponse(response);
  }

  // ✏️ Mettre à jour un poste (par ID)
  static Future<Map<String, dynamic>> updateUCPoste(String id, Map<String, dynamic> data) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/uc/postes/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
    return _handleResponse(response);
  }

  // ❌ Supprimer un poste
  static Future<Map<String, dynamic>> deleteUCPoste(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/uc/postes/$id'));
    return _handleResponse(response);
  }

  static Future<void> saveOrUpdatePoste(Map<String, dynamic> data) async {
    final id = data['ID_Usage'];
    final urlGet = Uri.parse('$baseUrl/api/uc/postes/$id');
    final urlPost = Uri.parse('$baseUrl/api/uc/postes');
    final urlPatch = Uri.parse('$baseUrl/api/uc/postes/$id');

    try {
      final getResponse = await http.get(urlGet);

      if (getResponse.statusCode == 200) {
        final response = await http.patch(urlPatch, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));

        if (response.statusCode != 200) {
          throw Exception("Erreur PATCH : ${response.statusCode} - ${response.body}");
        } else {
          print("✅ Poste mis à jour avec succès : $id");
        }
      } else {
        final response = await http.post(urlPost, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception("Erreur POST : ${response.statusCode} - ${response.body}");
        } else {
          print("✅ Poste créé avec succès : $id");
        }
      }
    } catch (e) {
      print('❌ Erreur enregistrement : $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📦 UC - POSTES en lecture
  // ---------------------------------------------------------------------------

  // récupère l'ensemble des données d'un individu pour un bilan (année ou simulation)
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getUCPostes(String codeIndividu, String valeurTemps) async {
    final response = await http.get(Uri.parse("$baseUrl/api/uc/postes?code_individu=$codeIndividu&valeur_temps=$valeurTemps"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur lors du chargement des postes");
    }
  }

  // récupère les données par Type Catégories
  // ---------------------------------------------------------------------------

  static Future<List<Poste>> getPostesByCategorie(String typeCategorie, String codeIndividu, String valeurTemps) async {
    final response = await http.get(Uri.parse('$baseUrl/api/uc/postes?code_individu=$codeIndividu&valeur_temps=$valeurTemps'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Poste.fromJson(json)).where((poste) => poste.typeCategorie == typeCategorie).toList();
    } else {
      throw Exception("Erreur lors de la récupération des postes");
    }
  }

  // récupère les données par Type de poste
  // ---------------------------------------------------------------------------

  static Future<Map<String, Map<String, double>>> getEmissionsByTypeAndYearAndUser(
    String filtre, // 'Tous', 'Usages', 'Equipements'
    String codeIndividu,
    String valeurTemps,
  ) async {
    List<Map<String, dynamic>> allData = await getUCPostes(codeIndividu, valeurTemps);

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
      result[typeCategorie]!["total"] = result[typeCategorie]!["total"]! + emission / 1000;
    }

    return result;
  }

  // récupère les données par sous Catégorie
  // ---------------------------------------------------------------------------

  static Future<List<Poste>> getPostesBysousCategorie(String sousCategorie, String codeIndividu, String valeurTemps) async {
    // Fonction de normalisation (accents, majuscules)
    String normalize(String s) => s.toLowerCase().replaceAll('é', 'e').replaceAll('è', 'e').trim();

    final allData = await getUCPostes(codeIndividu, valeurTemps);

    final filtered = allData.where((item) {
      final itemCat = normalize(item['Sous_Categorie'] ?? '');
      final targetCat = normalize(sousCategorie);
      return itemCat == targetCat;
    });

    return filtered.map((item) => Poste.fromJson(item)).toList();
  }

  // récupère les données par Type Catégorie et sous Catégorie
  // ---------------------------------------------------------------------------

  static Future<Map<String, Map<String, double>>> getEmissionsByCategoryAndSousCategorie(String codeIndividu, String valeurTemps) async {
    final List<Map<String, dynamic>> allData = await getUCPostes(codeIndividu, valeurTemps);

    final Map<String, Map<String, double>> result = {};

    for (final item in allData) {
      final String typeCategorie = item['Type_Categorie'] ?? 'Inconnu';
      final String sousCategorie = item['Sous_Categorie'] ?? 'Autre';
      final emission = (item['Emission_Calculee'] ?? 0).toDouble();

      result.putIfAbsent(typeCategorie, () => {});
      result[typeCategorie]![sousCategorie] = (result[typeCategorie]![sousCategorie] ?? 0) + emission / 1000;
    }

    return result;
  }

  // récupère les données par Type poste et Type Catégorie
  // ---------------------------------------------------------------------------

  static Future<Map<String, Map<String, double>>> getEmissionsFilteredByTypePosteGroupedByCategorie(
    String typePoste, // "Usage", "Equipement"
    String codeIndividu,
    String valeurTemps,
  ) async {
    final allData = await getUCPostes(codeIndividu, valeurTemps);

    // Filtrer par Type_Poste
    final filtered = allData.where((item) => item['Type_Poste'] == typePoste).toList();

    final Map<String, Map<String, double>> result = {};

    for (final item in filtered) {
      final categorie = item['Type_Categorie'] ?? 'Inconnu';
      final emission = (item['Emission_Calculee'] ?? 0).toDouble();

      result.putIfAbsent(categorie, () => {});
      result[categorie]!['total'] = (result[categorie]!['total'] ?? 0) + emission / 1000;
    }

    return result;
  }
}
