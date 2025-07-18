import 'package:flutter/material.dart';
import '../../models/fixture_prediction.dart';
import '../../services/resultado_service.dart';
import '../../utils/validator_util.dart';
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
    _futureFinished = ResultadoService.getFinalizadosCorrigidos();
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
            itemBuilder: (_, i) {
              final j = jogos[i];

              // dica principal
              final primaryStatus = validarTip(
                estrategia: j.advice,
                golsCasa: j.golsCasa!,
                golsFora: j.golsFora!,
                nomeCasa: j.home,
                nomeFora: j.away,
              );

              // dica secundária (pode ser null ou empty)
              String? sec = j.secondaryAdvice;
              String? secondaryStatus;
              if (sec != null && sec.trim().isNotEmpty) {
                final s = validarTip(
                  estrategia: sec,
                  golsCasa: j.golsCasa!,
                  golsFora: j.golsFora!,
                  nomeCasa: j.home,
                  nomeFora: j.away,
                );
                // transforma GREEN em MEIO, qualquer outro vira VOID
                secondaryStatus = s == 'GREEN' ? 'MEIO' : 'VOID';
              }

              return ReportCard(
                homeTeam: j.home,
                awayTeam: j.away,
                homeGoals: j.golsCasa!,
                awayGoals: j.golsFora!,
                prediction: j.advice,
                confidence: j.advicePct,
                status: primaryStatus,
                secondaryPrediction: sec,
                secondaryStatus: secondaryStatus,
              );
            },
          );
        },
      ),
    );
  }
}
