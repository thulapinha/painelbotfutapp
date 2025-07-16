import 'dart:convert';
import 'package:botfutapp/pages/grafico/stats_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dia_stats.dart';
import 'monthly_stats_chart.dart';


class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<DiaStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = carregarStats();
  }

  void _refresh() {
    setState(() {
      _statsFuture = carregarStats();
    });
  }

  Future<List<DiaStats>> carregarStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith('report_'))
        .map((k) => k.replaceFirst('report_', ''))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final List<DiaStats> lista = [];
    for (final dia in keys) {
      final raw = prefs.getString('report_$dia');
      if (raw == null) continue;
      final decoded = jsonDecode(raw) as List<dynamic>;
      int green = 0, red = 0;
      for (var item in decoded) {
        final result = (item['result'] as String).toUpperCase();
        if (result.contains('GREEN')) green++;
        if (result.contains('RED')) red++;
      }
      lista.add(DiaStats(data: dia, green: green, red: red));
    }
    return lista;
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
      body: FutureBuilder<List<DiaStats>>(
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

          final totalGreen = dados.fold(0, (sum, d) => sum + d.green);
          final totalRed = dados.fold(0, (sum, d) => sum + d.red);
          final acerto = (totalGreen + totalRed) > 0
              ? (totalGreen / (totalGreen + totalRed)) * 100
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("✅ GREEN total: $totalGreen", style: const TextStyle(fontSize: 16)),
                Text("❌ RED total: $totalRed", style: const TextStyle(fontSize: 16)),
                Text("🎯 Acerto geral: ${acerto.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                StatsChart(dados: dados),
                const SizedBox(height: 32),
                MonthlyStatsChart(dados: dados),
              ],
            ),
          );
        },
      ),
    );
  }
}
