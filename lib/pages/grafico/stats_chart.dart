import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'dia_stats.dart';

class StatsChart extends StatelessWidget {
  final List<DiaStats> dados;

  const StatsChart({required this.dados, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxY = dados.map((d) => d.total).fold(0, (a, b) => a > b ? a : b) + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "📅 Gráfico de desempenho diário",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY.toDouble(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= dados.length) return const SizedBox.shrink();
                      final d = dados[i];
                      final parts = d.data.split('-');
                      return Text("${parts[1]}/${parts[2]}", style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: dados.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(toY: d.green.toDouble(), width: 8, color: Colors.green),
                    BarChartRodData(toY: d.red.toDouble(), width: 8, color: Colors.red),
                  ],
                  barsSpace: 4,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            Icon(Icons.circle, color: Colors.green, size: 14),
            Text("GREEN", style: TextStyle(fontSize: 14)),
            Icon(Icons.circle, color: Colors.red, size: 14),
            Text("RED", style: TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        ...dados.take(7).map((d) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text("📆 ${d.data} → ✅ ${d.green} | ❌ ${d.red} | 🎯 ${d.pctGreen.toStringAsFixed(1)}%"),
        )),
      ],
    );
  }
}
