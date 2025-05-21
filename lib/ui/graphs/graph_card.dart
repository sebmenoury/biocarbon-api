import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:carbone_web/core/constants/app_colors.dart';
import 'package:carbone_web/core/constants/app_text.dart';
import 'package:carbone_web/core/constants/app_order.dart';

class GraphCard extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final bool compactLeftLegend;

  const GraphCard({
    super.key,
    required this.data,
    this.compactLeftLegend = false,
  });

  SideTitles getSideTitles(double maxY) {
    final safeMaxY = (maxY.isFinite && maxY > 0) ? maxY : 1.0;
    double interval = safeMaxY / 5;

    if (!interval.isFinite || interval <= 0) {
      debugPrint('⚠️ Interval fallback triggered. maxY: $maxY');
      interval = 1.0;
    }

    return SideTitles(
      showTitles: true,
      interval: interval,
      getTitlesWidget: (value, meta) {
        return Text(
          value.toStringAsFixed(0),
          style: const TextStyle(fontSize: 10),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderedCategories =
        AppOrder.typeCategoryOrder
            .where((cat) => data.containsKey(cat))
            .toList();

    final rawMaxY = orderedCategories
        .map((cat) {
          final values =
              data[cat]?.values.where((v) => v.isFinite && v >= 0).toList() ??
              [];
          return values.isNotEmpty ? values.reduce((a, b) => a + b) : 0.0;
        })
        .fold(0.0, (prev, e) => e > prev ? e : prev);

    final maxY = rawMaxY * 1.3;
    final safeMaxY = (!maxY.isFinite || maxY <= 0) ? 1.0 : maxY;

    final hasValidData = data.values.any(
      (m) => m.values.any((value) => value.isFinite && value >= 0),
    );

    if (!hasValidData) {
      return const Center(
        child: Text('Aucune donnée valide pour afficher le graphique'),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.38,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black.withOpacity(0.8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final cat = orderedCategories[group.x.toInt()];
                  final sousCats = data[cat]!;
                  final tooltipText = sousCats.entries
                      .map((e) => "${e.key} : ${e.value.toStringAsFixed(2)} t")
                      .join('\n');
                  return BarTooltipItem(
                    tooltipText,
                    const TextStyle(color: Colors.white, fontSize: 8),
                  );
                },
              ),
            ),
            alignment: BarChartAlignment.spaceAround,
            maxY: safeMaxY,
            barGroups: List.generate(orderedCategories.length, (i) {
              final cat = orderedCategories[i];
              final sousCats = data[cat]!;
              final order =
                  AppOrder.sousCategorieOrder[cat] ?? sousCats.keys.toList();

              final rodStackItems = <BarChartRodStackItem>[];
              double startY = 0;

              for (final label in order) {
                final value = sousCats[label];
                if (value != null && value.isFinite && value >= 0) {
                  final color = AppColors.categoryColors[label] ?? Colors.grey;
                  rodStackItems.add(
                    BarChartRodStackItem(startY, startY + value, color),
                  );
                  startY += value;
                }
              }

              final toY =
                  rodStackItems.isNotEmpty ? rodStackItems.last.toY : 0.0;

              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: toY,
                    rodStackItems: rodStackItems,
                    width: 32,
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                ],
              );
            }),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameWidget: RotatedBox(
                  quarterTurns: 4,
                  child: SizedBox(
                    height: 140,
                    width: compactLeftLegend ? 40 : 130,
                    child: const Center(
                      child: Text(
                        'tCO₂e/an',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                sideTitles: getSideTitles(safeMaxY),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= orderedCategories.length) {
                      return const SizedBox.shrink();
                    }

                    final category = orderedCategories[index];
                    final formattedCategory = AppText.shortLabel(category);

                    final values = data[category]?.values ?? [];
                    final emissions =
                        values.isNotEmpty
                            ? values
                                .where((v) => v.isFinite && v >= 0)
                                .fold(0.0, (a, b) => a + b)
                            : 0.0;

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedCategory,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            "${emissions.toStringAsFixed(2)} t",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              drawHorizontalLine: true,
              horizontalInterval: safeMaxY / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                  dashArray: [2, 4],
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                bottom: BorderSide(color: Colors.black, width: 1),
                left: BorderSide(color: Colors.black, width: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
