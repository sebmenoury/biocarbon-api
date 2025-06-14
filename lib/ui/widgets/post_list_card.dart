import 'package:flutter/material.dart';

class PostListCard extends StatelessWidget {
  final String title;
  final String emission;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostListCard({super.key, required this.title, required this.emission, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.replaceFirst(RegExp(r'^(Voitures|2-roues|Autres)\s*-\s*'), '');

    return InkWell(
      onTap: onTap, // 👈 appel du callback au clic
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(displayTitle, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal))],
              ),
            ),
            Padding(padding: const EdgeInsets.only(right: 4, top: 2), child: Text(emission, style: const TextStyle(fontSize: 11))),
          ],
        ),
      ),
    );
  }
}
