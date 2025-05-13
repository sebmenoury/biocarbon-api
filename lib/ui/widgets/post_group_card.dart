import 'package:flutter/material.dart';
import 'post_list_card.dart';
import '../layout/custom_card.dart';

class PostData {
  final String title;
  final Widget subtitle;
  final double emission;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  PostData({
    required this.title,
    required this.subtitle,
    required this.emission,
    required this.onEdit,
    required this.onDelete,
  });
}

class PostGroupCard extends StatelessWidget {
  final String sousCategorie;
  final List<PostData> posts;

  const PostGroupCard({
    super.key,
    required this.sousCategorie,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    final totalEmission = posts.fold<double>(0.0, (sum, p) => sum + p.emission);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sousCategorie,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 8),
          ...posts.map(
            (post) => PostListCard(
              title: post.title,
              subtitle: post.subtitle,
              emission: "${post.emission.toStringAsFixed(1)} kg",
              onEdit: post.onEdit,
              onDelete: post.onDelete,
            ),
          ),
          const Divider(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total : ${totalEmission.toStringAsFixed(1)} kg",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
