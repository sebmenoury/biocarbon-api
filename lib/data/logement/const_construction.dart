// lib/utils/const_construction.dart

double reductionParAnnee(int annee) {
  if (annee >= 2024) return 0.6;
  if (annee >= 2020) return 0.85;
  if (annee >= 2010) return 1;
  if (annee >= 1990) return 0.85;
  if (annee >= 1975) return 0.7;
  if (annee >= 1950) return 0.6;
  if (annee >= 1900) return 0.4;
  return 1.0;
}
