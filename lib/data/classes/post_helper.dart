import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PosteHelper {
  static Future<void> traiterPoste({
    required Map<String, dynamic> posteData,
    required String? idUsageInitial,
    required int anneeAchatInitiale,
    required int nouvelleAnneeAchat,
    required String newIdUsage,
  }) async {
    final int quantite = posteData["Quantite"] ?? 0;

    // 🔴 1. Si quantité = 0 → supprimer
    if (quantite <= 0) {
      if (idUsageInitial != null) {
        await ApiService.deleteUCPoste(idUsageInitial);
        debugPrint("🗑 Poste supprimé : $idUsageInitial");
      }
      return;
    }

    // 🟠 2. S'il y a changement d'année → supprimer et créer nouveau
    final anneeModifiee = nouvelleAnneeAchat != anneeAchatInitiale;
    if (idUsageInitial != null && (idUsageInitial != newIdUsage || anneeModifiee)) {
      await ApiService.deleteUCPoste(idUsageInitial);
      debugPrint("♻️ Ancien poste supprimé : $idUsageInitial");
    }

    // 🟢 3. Créer ou mettre à jour le poste
    posteData["ID_Usage"] = newIdUsage;
    posteData["Date_enregistrement"] = DateTime.now().toIso8601String();
    await ApiService.saveOrUpdatePoste(posteData);
    debugPrint("✅ Poste sauvegardé : $newIdUsage");
  }
}
