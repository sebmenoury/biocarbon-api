import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WaterfallChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final Map<String, Color> palette;

  const WaterfallChart({super.key, required this.data, required this.palette});

  @override
  Widget build(BuildContext context) {
    final sortedCategories =
        data.keys.toList()..sort(
          (a, b) => data[b]!.values
              .reduce((x, y) => x + y)
              .compareTo(data[a]!.values.reduce((x, y) => x + y)),
        );

    final barGroups = <BarChartGroupData>[];
    double maxY = 0;
    double cumulativeStart = 0;

    for (int i = 0; i < sortedCategories.length; i++) {
      final cat = sortedCategories[i];
      final sousCats = data[cat]!;
      final total = sousCats.values.fold(0.0, (a, b) => a + b);

      final rods = [
        BarChartRodData(
          toY: cumulativeStart + total,
          fromY: cumulativeStart,
          rodStackItems:
              sousCats.entries.map((entry) {
                final color = palette[entry.key] ?? Colors.grey;
                final item = BarChartRodStackItem(
                  cumulativeStart,
                  cumulativeStart + entry.value,
                  color,
                );
                cumulativeStart += entry.value;
                return item;
              }).toList(),
          width: 22,
          borderRadius: BorderRadius.circular(4),
        ),
      ];

      barGroups.add(BarChartGroupData(x: i, barRods: rods));
      if (cumulativeStart > maxY) maxY = cumulativeStart;
    }

    final targetLines = [
      {'label': 'Objectif 2 t (2050)', 'value': 2.0, 'color': Colors.green},
      {
        'label': 'Trajectoire 7,2 t (2035)',
        'value': 7.2,
        'color': Colors.orange,
      },
      {'label': 'Moyenne FR 9,4 t (2024)', 'value': 9.4, 'color': Colors.red},
      {
        'label': 'Moyenne FR 10,8 t (2017)',
        'value': 10.8,
        'color': Colors.purple,
      },
    ];

    final double total = data.values
        .expand((e) => e.values)
        .fold(0.0, (a, b) => a + b);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black.withOpacity(0.85),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final cat = sortedCategories[group.x.toInt()];
              final sousCats = data[cat]!;
              final tooltipText = sousCats.entries
                  .map((e) => '${e.key} : ${e.value.toStringAsFixed(2)} t')
                  .join('\n');
              return BarTooltipItem(
                tooltipText,
                const TextStyle(color: Colors.white, fontSize: 9),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: const RotatedBox(
              quarterTurns: 4,
              child: Text(
                "tCO₂e/an",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedCategories.length) {
                  return const SizedBox.shrink();
                }
                final label = sortedCategories[index];
                final emissions = data[label]!.values.fold(
                  0.0,
                  (a, b) => a + b,
                );
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Column(
                    children: [
                      Text(label, style: const TextStyle(fontSize: 10)),
                      Text(
                        '${emissions.toStringAsFixed(1)} t',
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
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines:
              targetLines.map((target) {
                return HorizontalLine(
                  y: target['value'] as double,
                  color: target['color'] as Color,
                  strokeWidth: 1,
                  dashArray: [4, 3],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment:
                        target['label'] == 'Objectif 2 t (2050)'
                            ? Alignment.topRight
                            : Alignment.topLeft,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: target['color'] as Color,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
