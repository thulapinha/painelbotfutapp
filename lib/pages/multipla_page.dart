import 'package:flutter/material.dart';
import '../models/fixture_prediction.dart';
import '../services/telegram_service.dart';

class MultiplaPage extends StatefulWidget {
  final Future<List<FixturePrediction>> future;
  const MultiplaPage({required this.future, Key? key}) : super(key: key);

  @override
  State<MultiplaPage> createState() => _MultiplaPageState();
}

class _MultiplaPageState extends State<MultiplaPage> {
  late Future<List<_EntradaMultipla>> _futureMultipla;

  @override
  void initState() {
    super.initState();
    _futureMultipla = _gerarMultipla(widget.future);
  }

  Future<List<_EntradaMultipla>> _gerarMultipla(
    Future<List<FixturePrediction>> future,
  ) async {
    final lista = await future;

    final entradas = <_EntradaMultipla>[];

    for (final m in lista) {
      final sugestoes = <_EntradaMultipla>[];

      // Estratégia: Dupla Chance
      if (m.doubleChance.isNotEmpty && m.doubleChancePct > 70) {
        sugestoes.add(
          _EntradaMultipla(
            partida: "${m.home} x ${m.away}",
            tipo: "Dupla Chance",
            label: m.doubleChance,
            prob: m.doubleChancePct,
          ),
        );
      }

      // Estratégia: Over 2.5
      if (m.over25Label != null && (m.over25Pct ?? 0) > 70) {
        sugestoes.add(
          _EntradaMultipla(
            partida: "${m.home} x ${m.away}",
            tipo: "Over 2.5",
            label: m.over25Label!,
            prob: m.over25Pct!,
          ),
        );
      }

      // Estratégia: Under 2.5
      if (m.under25Label != null && (m.under25Pct ?? 0) > 70) {
        sugestoes.add(
          _EntradaMultipla(
            partida: "${m.home} x ${m.away}",
            tipo: "Under 2.5",
            label: m.under25Label!,
            prob: m.under25Pct!,
          ),
        );
      }

      // Pegamos a melhor sugestão daquele jogo
      if (sugestoes.isNotEmpty) {
        sugestoes.sort((a, b) => b.prob.compareTo(a.prob));
        entradas.add(sugestoes.first);
      }
    }

    entradas.sort((a, b) => b.prob.compareTo(a.prob));
    return entradas.take(3).toList();
  }

  double _probToOdd(double prob) {
    final p = prob / 100;
    return p > 0 ? (1 / p).clamp(1.01, 10.0) : 1.01;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_EntradaMultipla>>(
      future: _futureMultipla,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final lista = snap.data ?? [];
        if (lista.length < 2) {
          return const Center(
            child: Text('Poucos jogos disponíveis para múltipla.'),
          );
        }

        final odds = lista.map((e) => _probToOdd(e.prob)).toList();
        final oddFinal = odds.fold(1.0, (a, b) => a * b);
        final probFinal =
            lista.map((e) => e.prob / 100).fold(1.0, (a, b) => a * b) * 100;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "🎯 Múltipla – Estratégias Variadas",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  final e = lista[i];
                  final odd = _probToOdd(e.prob);
                  final cor = e.prob >= 80
                      ? Colors.green.shade800
                      : Colors.orange.shade700;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text("⚽ ${e.partida}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "📌 ${e.tipo}: ${e.label}",
                            style: TextStyle(
                              color: cor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text("🧮 ${odd.toStringAsFixed(2)}"),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    "💰 Odd combinada: ${oddFinal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "🎯 Probabilidade estimada: ${probFinal.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text("Enviar múltipla ao Telegram"),
                    onPressed: () =>
                        _enviarMultipla(lista, oddFinal, probFinal),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _enviarMultipla(
    List<_EntradaMultipla> lista,
    double oddFinal,
    double probFinal,
  ) {
    final buf = StringBuffer();
    buf.writeln("🔥 BotFut – Múltipla do Dia 🔥");
    buf.writeln("🎯 Estratégia: Combinada");
    buf.writeln("💡 Entradas com foco em segurança e valor!\n");
    buf.writeln("---");

    for (final e in lista) {
      buf.writeln("⚽ ${e.partida}");
      buf.writeln("📌 ${e.tipo}: ${e.label}");
      buf.writeln("");
    }

    buf.writeln("---");
    buf.writeln("📈 Odd combinada: 💰 ${oddFinal.toStringAsFixed(2)}");
    buf.writeln(
      "🎲 Probabilidade Estimada: 🎯 ${probFinal.toStringAsFixed(1)}%",
    );

    TelegramService.sendMessage(buf.toString());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Múltipla enviada!")));
  }
}

class _EntradaMultipla {
  final String partida;
  final String tipo; // ex: Dupla Chance, Over 2.5
  final String label;
  final double prob;

  _EntradaMultipla({
    required this.partida,
    required this.tipo,
    required this.label,
    required this.prob,
  });
}
