import 'package:flutter/material.dart';

class CustomDropdownCompact extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String label;
  final ValueChanged<String?> onChanged;

  const CustomDropdownCompact({
    Key? key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Largeur = 50% de l'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = screenWidth / 2;

    return SizedBox(
      width: dropdownWidth,
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
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
                      height: 20, // Hauteur de ligne compacte
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(item, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
