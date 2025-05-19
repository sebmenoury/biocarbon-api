import 'package:flutter/material.dart';

void showChoixTypeBienDialog(
  BuildContext context,
  void Function(String) onSelected,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Quel type de bien ?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var type in [
              "Maison Principale",
              "Maison Secondaire",
              "Bien locatif",
            ])
              ListTile(
                title: Text(type),
                onTap: () {
                  Navigator.of(context).pop(); // Fermer le dialog
                  onSelected(type); // Appelle le callback
                },
              ),
          ],
        ),
      );
    },
  );
}
