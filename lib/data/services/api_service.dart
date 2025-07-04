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

  static Future<Map<String, dynamic>> getBienParId(String codeIndividu, String idBien) async {
    final response = await http.get(Uri.parse('https://biocarbon-api.onrender.com/api/uc/biens?code_individu=$codeIndividu'));

    if (response.statusCode == 200) {
      final List biens = jsonDecode(response.body);
      final bien = biens.firstWhere((b) => b['ID_Bien'] == idBien, orElse: () => throw Exception('Aucun bien trouvé avec cet ID'));
      return bien;
    } else {
      throw Exception('Erreur lors du chargement des biens');
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

  static Future<void> savePostesBulk(List<Map<String, dynamic>> postes) async {
    final response = await http.post(Uri.parse("$baseUrl/api/uc/postes/bulk"), headers: {"Content-Type": "application/json"}, body: jsonEncode(postes));

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de l'enregistrement en masse des postes");
    }
  }

  // ❌ Supprimer un poste
  static Future<Map<String, dynamic>> deleteUCPoste(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/uc/postes/$id'));
    return _handleResponse(response);
  }

  static Future<void> deleteAllPostes({required String codeIndividu, required String? idBien, required String valeurTemps, required String sousCategorie}) async {
    if (idBien == null || idBien.isEmpty) {
      throw Exception('ID_Bien manquant');
    }
    final uri = Uri.parse(
      '$baseUrl/delete_all?Code_Individu=$codeIndividu'
      '&ID_Bien=$idBien'
      '&Valeur_Temps=$valeurTemps'
      '&Sous_Categorie=$sousCategorie',
    );

    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception("Erreur suppression des postes: ${response.statusCode} - ${response.body}");
    } else {
      print('✅ Tous les postes $sousCategorie du bien $idBien supprimés.');
    }
  }

  static Future<void> deleteAllPostesSansBien({required String codeIndividu, required String valeurTemps, required String typeCategorie}) async {
    final uri = Uri.parse(
      '$baseUrl/delete_all_sans_bien?Code_Individu=$codeIndividu'
      '&Valeur_Temps=$valeurTemps'
      '&Type_Categorie=$typeCategorie',
    );

    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception("Erreur suppression des postes: ${response.statusCode} - ${response.body}");
    } else {
      print('✅ Tous les postes $typeCategorie ont été supprimés.');
    }
  }

  static Future<void> deleteAllPostesSansBiensousCategory({required String codeIndividu, required String valeurTemps, required String sousCategorie}) async {
    final uri = Uri.parse(
      '$baseUrl/delete_all_sans_bien?Code_Individu=$codeIndividu'
      '&Valeur_Temps=$valeurTemps'
      '&Sous_Categorie=$sousCategorie',
    );

    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception("Erreur suppression des postes: ${response.statusCode} - ${response.body}");
    } else {
      print('✅ Tous les postes $sousCategorie ont été supprimés.');
    }
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

  static Future<void> savePoste(Map<String, dynamic> data) async {
    final urlPost = Uri.parse('$baseUrl/api/uc/postes');

    try {
      final response = await http.post(urlPost, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur POST : ${response.statusCode} - ${response.body}');
      }
      print('✅ Poste créé avec succès : ${data['ID_Usage']}');
    } catch (e) {
      print('❌ Erreur enregistrement : $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📦 UC - POSTES en lecture
  // ---------------------------------------------------------------------------

  // requête générique avec filtres pour récupérer les postes
  // ---------------------------------------------------------------------------

  static Future<List<Poste>> getUCPostesFiltres({
    String? codeIndividu,
    String? annee,
    String? typePoste,
    String? typeTemps,
    String? valeurTemps,
    String? idBien,
    String? sousCategorie,
    String? typeCategorie,
    String? idUsage,
  }) async {
    final queryParameters = {
      if (codeIndividu != null) 'Code_Individu': codeIndividu,
      if (annee != null) 'Valeur_Temps': annee,
      if (typeTemps != null) 'Type_Temps': typeTemps,
      if (valeurTemps != null) 'Valeur_Temps': valeurTemps,
      if (idBien != null) 'ID_Bien': idBien,
      if (sousCategorie != null) 'Sous_Categorie': sousCategorie,
      if (typeCategorie != null) 'Type_Categorie': typeCategorie,
      if (idUsage != null) 'ID_Usage': idUsage,
      if (typePoste != null) 'Type_Poste': typePoste,
    };

    final uri = Uri.parse('$baseUrl/api/uc/postes').replace(queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Poste.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des postes filtrés');
    }
  }
  // requête générique avec filtres pour récupérer les émissions
  // ---------------------------------------------------------------------------

  static Future<Map<String, Map<String, double>>> getEmissionsAggregated({
    required String codeIndividu,
    required String valeurTemps,
    String? typePoste,
    String? typeCategorie,
    String? sousCategorie,
    String? idBien,
    required List<String> groupByFields,
  }) async {
    final postes = await getUCPostesFiltres(codeIndividu: codeIndividu, annee: valeurTemps, typeCategorie: typeCategorie, sousCategorie: sousCategorie, typePoste: typePoste, idBien: idBien);

    final Map<String, Map<String, double>> result = {};

    for (final poste in postes) {
      final keys =
          groupByFields.map((field) {
            switch (field) {
              case 'Type_Categorie':
                return poste.typeCategorie ?? 'Inconnu';
              case 'Sous_Categorie':
                return poste.sousCategorie ?? 'Autre';
              case 'Type_Poste':
                return poste.typePoste ?? 'Autre';
              default:
                return 'Autre';
            }
          }).toList();

      final primaryKey = keys.first;
      final secondaryKey = keys.length > 1 ? keys[1] : (poste.sousCategorie ?? 'total');

      final emission = (poste.emissionCalculee ?? 0) / 1000;

      result.putIfAbsent(primaryKey, () => {});
      result[primaryKey]![secondaryKey] = (result[primaryKey]![secondaryKey] ?? 0) + emission;
    }

    return result;
  }
}
