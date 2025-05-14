import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/layout/custom_card.dart';
import '../../ui/widgets/post_list_card.dart';
import '../../data/services/api_service.dart';
import '../../data/models/poste.dart';

class PosteListScreen extends StatefulWidget {
  final String sousCategorie;
  final String codeIndividu;
  final String valeurTemps;

  const PosteListScreen({
    super.key,
    required this.sousCategorie,
    required this.codeIndividu,
    required this.valeurTemps,
  });

  @override
  State<PosteListScreen> createState() => _PosteListScreenState();
}

class _PosteListScreenState extends State<PosteListScreen> {
  late Future<List<Poste>> postesFuture;

  @override
  void initState() {
    super.initState();
    postesFuture = ApiService.getPostesByCategorie(
      widget.sousCategorie,
      widget.codeIndividu,
      widget.valeurTemps,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            widget.sousCategorie,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      children: [
        FutureBuilder<List<Poste>>(
          future: postesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Erreur : ${snapshot.error}"),
              );
            }

            final postes = snapshot.data ?? [];

            if (postes.isEmpty) {
              return CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Déclarer mes ${widget.sousCategorie}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            }

            final total = postes.fold<double>(
              0,
              (sum, p) => sum + (p.emissionCalculee ?? 0),
            );

            postes.sort(
              (a, b) =>
                  (b.emissionCalculee ?? 0).compareTo(a.emissionCalculee ?? 0),
            );

            return CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.sousCategorie,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Total : ${total.round()} kg",
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(thickness: 0.5, height: 16),

                  ...List.generate(postes.length * 2 - 1, (index) {
                    if (index.isEven) {
                      final poste = postes[index ~/ 2];
                      return PostListCard(
                        title: poste.nomPoste ?? 'Sans nom',
                        emission:
                            "${poste.emissionCalculee?.toStringAsFixed(0) ?? '0'} kgCO₂",
                        onEdit: () {},
                        onDelete: () {},
                      );
                    } else {
                      return const Divider(
                        height: 1,
                        thickness: 0.2,
                        color: Colors.grey,
                      );
                    }
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
