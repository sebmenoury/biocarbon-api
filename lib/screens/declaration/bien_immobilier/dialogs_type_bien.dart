import 'package:flutter/material.dart';

void showChoixTypeBienDialog(
  BuildContext context,
  void Function(String) onSelected, {
  bool hasLogementPrincipal = false, // 👈 paramètre ajouté
}) {
  final typesDisponibles =
      hasLogementPrincipal ? ["Logement secondaire"] : ["Logement principal", "Logement secondaire"];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Quel type de logement ?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var type in typesDisponibles)
              ListTile(
                title: Text(type, style: const TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(type);
                },
              ),
          ],
        ),
      );
    },
  );
}
