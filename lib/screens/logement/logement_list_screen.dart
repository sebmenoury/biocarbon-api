import 'package:flutter/material.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/widgets/post_group_card.dart';
import '../../data/services/api_service.dart';

class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() => _LogementListScreenState();
}

class _LogementListScreenState extends State<LogementListScreen> {
  Map<String, List<PostData>> groupedPosts = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    const individu = 'SEBASTIEN'; // à rendre dynamique plus tard
    const annee = '2024';

    final data = await ApiService.getPostesByCategorie(
      'Logement',
      individu,
      annee,
    );

    final Map<String, List<PostData>> groupMap = {};
    for (var item in data) {
      final sousCat = item.sousCategorie ?? 'Autre';
      final titre = item.nomPoste ?? '';
      final quantite = item.quantite ?? '';
      final unite = item.unite ?? '';
      final emission = item.emissionCalculee?.toDouble() ?? 0;

      final post = PostData(
        title: titre,
        subtitle: '$quantite $unite',
        emission: emission,
        onEdit: () {}, // à connecter
        onDelete: () {}, // à connecter
      );

      groupMap.putIfAbsent(sousCat, () => []).add(post);
    }

    setState(() {
      groupedPosts = groupMap;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: "Logement",
      children:
          loading
              ? [const Center(child: CircularProgressIndicator())]
              : [
                ...groupedPosts.entries.map(
                  (entry) => PostGroupCard(
                    sousCategorie: entry.key,
                    posts: entry.value,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    onPressed: () {
                      // logique d’ajout
                    },
                  ),
                ),
              ],
    );
  }
}
