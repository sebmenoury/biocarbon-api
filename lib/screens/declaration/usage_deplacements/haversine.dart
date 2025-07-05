import 'dart:math';

class Haversine {
  /// Retourne la distance entre deux points (en km) selon la formule de Haversine
  static double calculerDistanceKm({required double lat1, required double lon1, required double lat2, required double lon2}) {
    const rayonTerreKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = pow(sin(dLat / 2), 2) + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return rayonTerreKm * c;
  }

  static double _degToRad(double deg) => deg * pi / 180;
}
