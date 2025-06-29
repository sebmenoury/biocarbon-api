import 'package:flutter/material.dart';

class CustomNumberInput extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  final String label;
  final int min;
  final int max;
  final String suffix;

  const CustomNumberInput({super.key, required this.value, required this.onChanged, required this.label, this.min = 0, this.max = 9999, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        IconButton(icon: const Icon(Icons.remove), onPressed: value > min ? () => onChanged(value - 1) : null),
        Text('$value$suffix'),
        IconButton(icon: const Icon(Icons.add), onPressed: value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}
