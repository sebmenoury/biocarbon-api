import 'package:flutter/material.dart';

void showChoixTypeBienDialog(
  BuildContext context,
  void Function(String) onSelected,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white.withOpacity(
          0.95,
        ), // fond blanc translucide
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Quel type de bien ?",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var type in [
              "Maison Principale",
              "Maison Secondaire",
              "Bien locatif",
            ])
              ListTile(
                title: Text(
                  type,
                  style: const TextStyle(fontSize: 12), // taille 12
                ),
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
