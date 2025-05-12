import 'package:flutter/material.dart';

class PostListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emission;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emission,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Wrap(
          spacing: 8,
          children: [
            Text(emission, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
