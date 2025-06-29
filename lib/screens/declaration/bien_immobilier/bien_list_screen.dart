import 'package:flutter/material.dart';
import '../../../ui/layout/base_screen.dart';
import '../../../ui/layout/custom_card.dart';
import '../../../data/services/api_service.dart';
import 'dialogs_type_bien.dart';
import 'bien_immobilier.dart';
import 'bien_declaration_screen.dart';
import '../../main/mes_donnees_screen.dart';

class BienListScreen extends StatefulWidget {
  const BienListScreen({super.key});

  @override
  State<BienListScreen> createState() => _BienListScreenState();
}

class _BienListScreenState extends State<BienListScreen> {
  late Future<List<Map<String, dynamic>>> biensFuture;

  @override
  void initState() {
    super.initState();
    biensFuture = ApiService.getBiens("BASILE");
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: Text("Mes biens immobiliers", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              iconSize: 18,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MesDonneesScreen()), // ⬅️ remplace avec ton écran de départ
                  (route) => false, // ⬅️ supprime tous les écrans précédents
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),

      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: biensFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasError) {
              return Padding(padding: const EdgeInsets.all(16), child: Text("Erreur : ${snapshot.error}"));
            }

            final biens =
                (snapshot.data ?? [])..sort((a, b) {
                  final ordre = {'Logement principal': 0, 'Logement secondaire': 1};
                  return (ordre[a['Type_Bien']] ?? 2).compareTo(ordre[b['Type_Bien']] ?? 2);
                });
            final bool hasLogementPrincipal = biens.any((b) => b['Type_Bien'] == 'Logement principal');

            List<Widget> widgets = [];
            // 💡 Texte explicatif toujours affiché
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  "🏠 Ici, vous déclarez les biens immobiliers que vous possédez ou que vous louez. \n",
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.justify,
                ),
              ),
            );

            // 👉 Cartes des biens existants
            if (biens.isNotEmpty) {
              widgets.addAll(
                biens.map((bien) {
                  final type = bien['Type_Bien'] ?? '';
                  final denom = bien['Dénomination'] ?? '';
                  final adresse = bien['Adresse'] ?? '';
                  final nbProp = bien['Nb_Proprietaires']?.toString() ?? '-';
                  final nbHab = bien['Nb_Habitants']?.toString() ?? '-';
                  final bienObj = BienImmobilier.fromMap(bien); // 👈 transforme le map en objet

                  return CustomCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.home, size: 16, color: Colors.teal),
                            const SizedBox(width: 6),
                            Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => BienDeclarationScreen(bienExistant: bienObj)));
                              },
                              child: const Icon(Icons.chevron_right, size: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                        const SizedBox(height: 8),
                        Text("Dénomination : $denom", style: const TextStyle(fontSize: 12)),
                        const Divider(height: 8, thickness: 0.2, color: Colors.grey),
                        Text("Adresse : $adresse", style: const TextStyle(fontSize: 12)),
                        const Divider(height: 8, thickness: 0.2, color: Colors.grey),
                        Text("Nombre propriétaires : $nbProp", style: const TextStyle(fontSize: 12)),
                        const Divider(height: 8, thickness: 0.2, color: Colors.grey),
                        Text("Nombre habitants : $nbHab", style: const TextStyle(fontSize: 12)),
                        const Divider(height: 8, thickness: 0.2, color: Colors.grey),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            ['TRUE', true].contains(bien['Inclure_dans_bilan']) ? "Inclus dans le bilan" : "Non inclus dans le bilan",
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            }

            /// 👇 Bouton ajouter (toujours affiché)
            widgets.add(
              CustomCard(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: InkWell(
                  onTap: () {
                    showChoixTypeBienDialog(
                      context,
                      (selectedType) {
                        if (selectedType == 'Logement principal' && hasLogementPrincipal) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Un logement principal est déjà déclaré.")));
                          return;
                        }

                        Navigator.push(context, MaterialPageRoute(builder: (_) => BienDeclarationScreen(typeBienInitial: selectedType))).then((_) {
                          // ne fait rien ici volontairement
                        });
                      },
                      hasLogementPrincipal: hasLogementPrincipal, // 👈 facultatif si tu filtres le choix en amont
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text("Ajouter un bien immobilier", style: TextStyle(fontSize: 12)), Icon(Icons.chevron_right, size: 14)],
                  ),
                ),
              ),
            );

            return Column(children: widgets);
          },
        ),
      ],
    );
  }
}
