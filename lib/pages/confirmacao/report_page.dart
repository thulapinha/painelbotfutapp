import 'package:flutter/material.dart';
import '../../models/fixture_prediction.dart';
import '../../utils/estrategia_util.dart';
import '../../utils/validator_util.dart';
import 'report_card.dart';

class ReportPage extends StatelessWidget {
  final List<FixturePrediction> todosJogos;

  const ReportPage({required this.todosJogos, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. filtrar apenas jogos que já têm resultado final
    final finalizados = todosJogos.where((j) {
      return j.date.isBefore(DateTime.now()) &&
          j.golsCasa != null &&
          j.golsFora != null;
    }).toList();

    // 2. preparar histórico
    int green = 0, red = 0, voids = 0;

    final cards = finalizados.map((j) {
      final estrategia = getMelhorSugestao(j).label;
      final status = validarTip(
        estrategia: estrategia,
        golsCasa: j.golsCasa!,
        golsFora: j.golsFora!,
        nomeCasa: j.home,
        nomeFora: j.away,
      );

      if (status == "GREEN") green++;
      else if (status == "RED") red++;
      else voids++;

      return ReportCard(
        estrategia: estrategia,
        status: status,
        golsCasa: j.golsCasa!,
        golsFora: j.golsFora!,
        nomeCasa: j.home,
        nomeFora: j.away,
      );
    }).toList();

    final total = green + red + voids;
    final acerto = total > 0 ? (green / total * 100).toStringAsFixed(1) : "0";

    return Scaffold(
      appBar: AppBar(title: const Text("📈 Relatório de Tips")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "✅ Assertividade: $acerto% ($green de $total)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? const Center(child: Text("Nenhum jogo finalizado disponível"))
                : ListView(children: cards),
          ),
        ],
      ),
    );
  }
}
