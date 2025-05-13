import 'package:flutter/material.dart';

class PostListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emission;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emission,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 2),
            child: Text(
              emission,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
