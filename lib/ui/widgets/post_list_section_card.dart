import 'package:flutter/material.dart';
import '../layout/custom_card.dart'; // adapte selon ton import réel
import 'post_list_card.dart'; // adapte selon ton import réel
import '../../data/classes/poste_postes.dart'; // adapte selon le type réel

class PostListSectionCard extends StatelessWidget {
  final String sousCat;
  final List<Poste> postes;
  final double total;
  final VoidCallback? onTap;

  const PostListSectionCard({super.key, required this.sousCat, required this.postes, required this.total, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec total + chevron cliquable
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$sousCat", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.translucent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text("${total.round()} kgCO₂", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 8),
          ...List.generate(postes.length * 2 - 1, (index) {
            if (index.isEven) {
              final poste = postes[index ~/ 2];
              return PostListCard(
                title: poste.nomPoste ?? 'Sans nom',
                emission: "${poste.emissionCalculee?.round() ?? 0} kgCO₂",
                onTap: () {
                  print("🚗 Tap sur ${poste.nomPoste}");
                  // Navigation ou popup à implémenter
                },
                onEdit: () {
                  // ouvrir formulaire de modif
                },
                onDelete: () {
                  // action suppression
                },
              );
            } else {
              return const Divider(height: 1, thickness: 0.2, color: Colors.grey);
            }
          }),
        ],
      ),
    );
  }
}
