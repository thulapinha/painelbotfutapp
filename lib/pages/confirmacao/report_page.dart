// lib/pages/confirmacao/report_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/fixture_prediction.dart';
import '../../services/resultado_service.dart';
import 'report_card.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<List<FixturePrediction>> _futureFinished;

  @override
  void initState() {
    super.initState();
    _futureFinished = _corrigirESalvarResultados();
  }

  Future<List<FixturePrediction>> _corrigirESalvarResultados() async {
    final corrigidos = await ResultadoService.getFinalizadosCorrigidos();

    // Salva histórico corrigido do dia
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final key = 'resultadosCorrigidos_$today';
    final jsonStr = jsonEncode(corrigidos.map((e) => e.toJson()).toList());
    await prefs.setString(key, jsonStr);

    return corrigidos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Resultados')),
      body: FutureBuilder<List<FixturePrediction>>(
        future: _futureFinished,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }

          final jogos = snap.data!;
          if (jogos.isEmpty) {
            return const Center(child: Text('Nenhum jogo finalizado hoje.'));
          }

          return ListView.builder(
            itemCount: jogos.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (ctx, i) {
              final j = jogos[i];

              final parts = j.advice.split(':');
              final prediction = parts.length > 1
                  ? parts.last.trim()
                  : j.advice.trim();
              final confidence = j.advicePct;
              final golsCasa = j.golsCasa!;
              final golsFora = j.golsFora!;

              final actualWinner = golsCasa > golsFora
                  ? j.home
                  : golsFora > golsCasa
                  ? j.away
                  : 'empate';

              final predLower = prediction.toLowerCase();
              final actualLower = actualWinner.toLowerCase();
              String status;
              if (actualWinner == 'empate') {
                status = 'VOID';
              } else if (predLower.contains(actualLower)) {
                status = 'GREEN';
              } else {
                status = 'RED';
              }

              return ReportCard(
                homeTeam: j.home,
                awayTeam: j.away,
                homeGoals: golsCasa,
                awayGoals: golsFora,
                prediction: prediction,
                confidence: confidence,
                status: status,
              );
            },
          );
        },
      ),
    );
  }
}
