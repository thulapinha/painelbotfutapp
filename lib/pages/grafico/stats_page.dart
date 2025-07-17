import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/fixture_prediction.dart';
import 'dia_stats.dart';
import 'monthly_stats_chart.dart';
import 'stats_chart.dart';

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
        .where((k) => k.startsWith('resultadosCorrigidos_'))
        .map((k) => k.replaceFirst('resultadosCorrigidos_', ''))
        .toList()
      ..sort((a, b) => b.compareTo(a)); // mais recentes primeiro

    final List<DiaStats> lista = [];

    for (final dia in keys) {
      final raw = prefs.getString('resultadosCorrigidos_$dia');
      if (raw == null) continue;

      final decoded = jsonDecode(raw) as List;
      final jogos = decoded
          .map((e) => FixturePrediction.fromJson(e))
          .where((j) =>
      j.statusShort == 'FT' &&
          j.golsCasa != null &&
          j.golsFora != null)
          .toList();

      int green = 0, red = 0;

      for (final j in jogos) {
        final parts = j.advice.split(':');
        final prediction = parts.length > 1 ? parts.last.trim() : j.advice;

        final resultado = j.golsCasa! > j.golsFora!
            ? j.home
            : j.golsFora! > j.golsCasa!
            ? j.away
            : 'empate';

        if (resultado == 'empate') continue;

        if (prediction.toLowerCase().contains(resultado.toLowerCase())) {
          green++;
        } else {
          red++;
        }
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
