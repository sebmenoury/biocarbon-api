import 'package:flutter/material.dart';

class FrequenceSlider extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const FrequenceSlider({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Fréquence de ce trajet (par an)", style: TextStyle(fontSize: 12)),
        Slider(value: selected.toDouble(), min: 1, max: 12, divisions: 11, label: "$selected / an", onChanged: (double value) => onChanged(value.toInt())),
      ],
    );
  }
}
