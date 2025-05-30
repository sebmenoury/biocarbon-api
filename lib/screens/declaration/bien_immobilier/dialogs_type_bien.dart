import 'package:flutter/material.dart';

void showChoixTypeBienDialog(BuildContext context, void Function(String) onSelected) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95), // fond blanc translucide
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Quel type de logement ?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var type in ["Logement Principal", "Logement Secondaire"])
              ListTile(
                title: Text(
                  type,
                  style: const TextStyle(fontSize: 11), // taille 12
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
