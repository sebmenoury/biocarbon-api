import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../screens/declaration/poste_list_screen.dart';
import '../../screens/declaration/eqt_vehicules/vehicule_screen.dart';

class PosteVehiculeEntryPoint extends StatefulWidget {
  final String codeIndividu;
  final String valeurTemps;
  final String idBien; // ✅ remplacé

  const PosteVehiculeEntryPoint({Key? key, required this.codeIndividu, required this.valeurTemps, required this.idBien}) : super(key: key);

  @override
  State<PosteVehiculeEntryPoint> createState() => _PosteVehiculeEntryPointState();
}

class _PosteVehiculeEntryPointState extends State<PosteVehiculeEntryPoint> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    fetchAndRedirect();
  }

  Future<void> fetchAndRedirect() async {
    final postes = await ApiService.getUCPostesFiltres(sousCategorie: "Véhicules", codeIndividu: widget.codeIndividu, annee: widget.valeurTemps);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_navigated) {
        _navigated = true;

        if (postes.isEmpty) {
          // 🚗 Redirige vers l’écran de déclaration directe
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => VehiculeScreen(
                    codeIndividu: widget.codeIndividu,
                    idBien: widget.idBien,
                    onSave: () {
                      // Rafraîchissement de la liste si besoin
                      setState(() {});
                    },
                  ),
            ),
          );
        } else {
          // 📋 Redirige vers la liste des postes existants
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => PosteListScreen(
                    typeCategorie: "Déplacements",
                    sousCategorie: "Véhicules",
                    codeIndividu: widget.codeIndividu,
                    valeurTemps: widget.valeurTemps,
                    idBien: widget.idBien,
                    onAddPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => VehiculeScreen(
                                codeIndividu: widget.codeIndividu,
                                idBien: widget.idBien,
                                onSave: () {
                                  setState(() {});
                                },
                              ),
                        ),
                      );
                    },
                  ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
