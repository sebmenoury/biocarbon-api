import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
    double cumulativeStart = 0;
    double maxY = 0;

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

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black.withOpacity(0.8),
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
            axisNameWidget: RotatedBox(
              quarterTurns: 4,
              child: SizedBox(
                height: 140,
                width: 200,
                child: Center(
                  child: Text(
                    'tCO₂e/an',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return Container();
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 9),
                );
              },
              reservedSize: 28,
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
                final category = sortedCategories[index];
                final emissions = data[category]!.values.reduce(
                  (a, b) => a + b,
                );
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category, style: const TextStyle(fontSize: 10)),
                      Text(
                        '${emissions.toStringAsFixed(2)} t',
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
                  dashArray: [5, 3],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment:
                        target['label'] == 'Objectif 2 t (2050)'
                            ? Alignment.topRight
                            : Alignment.topLeft,
                    style: TextStyle(
                      fontSize: 9,
                      color: target['color'] as Color,
                      fontWeight: FontWeight.w500,
                    ),
                    labelResolver: (_) => target['label'] as String,
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
