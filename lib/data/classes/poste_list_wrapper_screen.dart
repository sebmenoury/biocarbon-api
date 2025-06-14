import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../screens/declaration/poste_list_screen.dart';
import '../../screens/declaration/eqt_vehicules/vehicule_screen.dart';

class PosteVehiculeEntryPoint extends StatefulWidget {
  final String codeIndividu;
  final String valeurTemps;
  final String denominationBien; // ✅

  const PosteVehiculeEntryPoint({Key? key, required this.codeIndividu, required this.valeurTemps, required this.denominationBien}) : super(key: key);

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
    final postes = await ApiService.getPostesBysousCategorie("Véhicules", widget.codeIndividu, widget.valeurTemps);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_navigated) {
        _navigated = true;

        if (postes.isEmpty) {
          // 🚗 Redirige vers l’écran de déclaration directe
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VehiculeScreen(codeIndividu: widget.codeIndividu, denominationBien: widget.denominationBien)));
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
                    denominationBien: widget.denominationBien,
                    onAddPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => VehiculeScreen(codeIndividu: widget.codeIndividu, denominationBien: widget.denominationBien)));
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
