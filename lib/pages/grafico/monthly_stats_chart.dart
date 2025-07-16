import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'dia_stats.dart';

class MonthlyStatsChart extends StatelessWidget {
  final List<DiaStats> dados;

  const MonthlyStatsChart({required this.dados, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final agrupado = _agruparPorMes(dados);
    final listaFinal = agrupado.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxY = listaFinal.map((e) => e.value.total).fold(0, (a, b) => a > b ? a : b) + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text("📆 Gráfico Mensal de Desempenho", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY.toDouble(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= listaFinal.length) return const SizedBox.shrink();
                      final k = listaFinal[i].key.split('-');
                      return Text("${k[1]}/${k[0]}", style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: listaFinal.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(toY: m.green.toDouble(), color: Colors.green, width: 10),
                    BarChartRodData(toY: m.red.toDouble(), color: Colors.red, width: 10),
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
          children: const [
            Icon(Icons.circle, color: Colors.green, size: 14),
            Text("GREEN", style: TextStyle(fontSize: 14)),
            Icon(Icons.circle, color: Colors.red, size: 14),
            Text("RED", style: TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        ...listaFinal.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
              "📆 ${e.key} → ✅ ${e.value.green} | ❌ ${e.value.red} | 🎯 ${e.value.pctGreen.toStringAsFixed(1)}%"),
        )),
      ],
    );
  }

  Map<String, DiaStats> _agruparPorMes(List<DiaStats> dias) {
    final Map<String, DiaStats> mapa = {};
    for (final d in dias) {
      final parts = d.data.split('-'); // yyyy-MM-dd
      final chave = "${parts[0]}-${parts[1]}"; // mês: yyyy-MM
      final atual = mapa[chave];
      if (atual == null) {
        mapa[chave] = DiaStats(data: chave, green: d.green, red: d.red);
      } else {
        mapa[chave] = DiaStats(
          data: chave,
          green: atual.green + d.green,
          red: atual.red + d.red,
        );
      }
    }
    return mapa;
  }
}
