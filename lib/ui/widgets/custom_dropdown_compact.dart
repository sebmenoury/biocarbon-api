import 'package:flutter/material.dart';

class CustomDropdownCompact extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String label;
  final ValueChanged<String?> onChanged;
  final double width;

  const CustomDropdownCompact({
    Key? key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.width = 120, // par défaut, largeur réduite
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        hint: Text("Sélectionner $label", style: const TextStyle(fontSize: 11)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        ),
        style: const TextStyle(fontSize: 11),
        items:
            items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: SizedBox(
                  height: 10, // réduit la hauteur de la ligne
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(item, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11)),
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
