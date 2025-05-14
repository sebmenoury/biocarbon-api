import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../ui/layout/base_screen.dart';
import '../../ui/widgets/post_group_card.dart';
import '../../data/models/poste.dart';

class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() => _LogementListScreenState();
}

class _LogementListScreenState extends State<LogementListScreen> {
  late Future<List<Poste>> postesFuture;

  @override
  void initState() {
    super.initState();
    postesFuture = ApiService.getPostesByCategorie(
      "Logement",
      "BASILE", // ✅ utilisateur corrigé
      "2025",
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: const Text(
        "Logement",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      child: FutureBuilder<List<Poste>>(
        future: postesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final data = snapshot.data ?? [];

          // 🔁 Regrouper les postes par sous-catégorie
          final Map<String, List<PostData>> groupedPosts = {};
          for (var item in data) {
            final sousCat = item.sousCategorie ?? 'Autre';
            final titre = item.nomPoste ?? '';
            final emission = item.emissionCalculee?.toDouble() ?? 0;

            final post = PostData(
              title: titre,
              emission: emission,
              onEdit: () {}, // à connecter
              onDelete: () {}, // à connecter
            );

            groupedPosts.putIfAbsent(sousCat, () => []).add(post);
          }

          if (groupedPosts.isEmpty) {
            return const Center(child: Text("Aucun poste enregistré."));
          }

          // ✅ Calcul du total global d’émission
          final totalEmissionGlobal = groupedPosts.values
              .expand((list) => list)
              .fold<double>(0, (sum, p) => sum + p.emission);

          // ✅ Trier les groupes par émissions décroissantes
          final sortedEntries =
              groupedPosts.entries.toList()..sort((a, b) {
                final aTotal = a.value.fold<double>(
                  0,
                  (sum, p) => sum + p.emission,
                );
                final bTotal = b.value.fold<double>(
                  0,
                  (sum, p) => sum + p.emission,
                );
                return bTotal.compareTo(aTotal);
              });

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ...sortedEntries.map(
                (entry) => PostGroupCard(
                  sousCategorie: entry.key,
                  posts: entry.value,
                  totalCategorieEmission: totalEmissionGlobal,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
