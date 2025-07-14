// lib/pages/stats_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<_DiaStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _DiaStats.reconstruirRelatorios();
  }

  void _refresh() {
    setState(() {
      _statsFuture = _DiaStats.reconstruirRelatorios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Estatísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<_DiaStats>>(
        future: _statsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }

          final dados = snap.data!;
          if (dados.isEmpty) {
            return const Center(child: Text('Nenhuma estatística disponível.'));
          }

          final greenTotal = dados.fold(0, (sum, d) => sum + d.green);
          final redTotal   = dados.fold(0, (sum, d) => sum + d.red);
          final acertos = (greenTotal + redTotal) > 0
              ? (greenTotal / (greenTotal + redTotal)) * 100
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (greenTotal + redTotal).toDouble() + 2,
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
                              final parts = dados[i].data.split('-');
                              return Text('${parts[1]}/${parts[2]}',
                                  style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: dados.asMap().entries.map((e) {
                        final i = e.key;
                        final d = e.value;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(toY: d.green.toDouble(), color: Colors.green),
                            BarChartRodData(toY: d.red.toDouble(),   color: Colors.red),
                          ],
                          barsSpace: 4,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text("✅ GREEN: $greenTotal    ❌ RED: $redTotal",
                    style: const TextStyle(fontSize: 16)),
                Text("🎯 Acerto Total: ${acertos.toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DiaStats {
  final String data;
  final int green;
  final int red;

  _DiaStats({required this.data, required this.green, required this.red});

  double get pctGreen {
    final total = green + red;
    return total == 0 ? 0 : (green / total) * 100;
  }

  static Future<List<_DiaStats>> reconstruirRelatorios() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith('report_'))
        .map((k) => k.replaceFirst('report_', ''))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final List<_DiaStats> lista = [];
    for (final dia in keys) {
      final raw = prefs.getString('report_$dia');
      if (raw == null) continue;
      final decoded = jsonDecode(raw) as List<dynamic>;
      var green = 0, red = 0;
      for (var item in decoded) {
        final result = (item['result'] as String).toUpperCase();
        if (result.contains('GREEN')) green++;
        if (result.contains('RED'))   red++;
      }
      lista.add(_DiaStats(data: dia, green: green, red: red));
    }
    return lista;
  }
}
