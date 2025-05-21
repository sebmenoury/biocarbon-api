import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../screens/detail/poste_list_screen.dart';
import '../../screens/deplacements/vehicule_screen.dart';

class PosteVehiculeEntryPoint extends StatefulWidget {
  final String codeIndividu;
  final String valeurTemps;

  const PosteVehiculeEntryPoint({super.key, required this.codeIndividu, required this.valeurTemps});

  @override
  State<PosteVehiculeEntryPoint> createState() => _PosteVehiculeEntryPointState();
}

class _PosteVehiculeEntryPointState extends State<PosteVehiculeEntryPoint> {
  bool _navigated = false;
  bool _isLoading = true;

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
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VehiculeScreen()));
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => PosteListScreen(
                    typeCategorie: "Déplacements",
                    sousCategorie: "Véhicules",
                    codeIndividu: widget.codeIndividu,
                    valeurTemps: widget.valeurTemps,
                    onAddPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiculeScreen()));
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
