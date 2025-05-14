import 'package:flutter/material.dart';
import 'post_list_card.dart';
import '../layout/custom_card.dart';

class PostData {
  final String title;
  final double emission;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  PostData({
    required this.title,
    required this.emission,
    required this.onEdit,
    required this.onDelete,
  });
}

class PostGroupCard extends StatelessWidget {
  final String sousCategorie;
  final List<PostData> posts;
  final double totalCategorieEmission; // nécessaire pour calculer le %

  const PostGroupCard({
    super.key,
    required this.sousCategorie,
    required this.posts,
    required this.totalCategorieEmission,
  });

  @override
  Widget build(BuildContext context) {
    final totalEmission = posts.fold<double>(0.0, (sum, p) => sum + p.emission);
    final pourcentage =
        totalCategorieEmission > 0
            ? (totalEmission / totalCategorieEmission * 100).toStringAsFixed(1)
            : "0";

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$sousCategorie ($pourcentage%)",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 8),
          ...posts.map(
            (post) => PostListCard(
              title: post.title,
              emission: "${post.emission.toStringAsFixed(0)} kg",
              onEdit: post.onEdit,
              onDelete: post.onDelete,
            ),
          ),
          const Divider(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total : ${totalEmission.toStringAsFixed(0)} kg",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
