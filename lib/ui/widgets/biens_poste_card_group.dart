import 'package:flutter/material.dart';

class BienPosteCardGroup extends StatelessWidget {
  final Map<String, dynamic> bien;
  final List<Map<String, dynamic>> postes;
  final String sousCategorie;
  final VoidCallback onAdd;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;

  const BienPosteCardGroup({
    super.key,
    required this.bien,
    required this.postes,
    required this.sousCategorie,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nomBien = bien['Description'] ?? 'Bien inconnu';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏠 $nomBien',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...postes.map(
          (poste) => Card(
            child: ListTile(
              title: Text(
                '${poste['Nom_Usage'] ?? "Mesure"} : ${poste['Emission_Calculee'] ?? "-"} kgCO₂',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onEdit(poste),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onDelete(poste),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une mesure'),
        ),
        const Divider(height: 32),
      ],
    );
  }
}
