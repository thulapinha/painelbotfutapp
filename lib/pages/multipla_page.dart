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
  late Future<List<MultiplaSuggestion>> _futureSuggestions;

  // Threshold mínimo para incluir Over/Under/etc
  final double _extraThreshold = 65.0;
  // Quantas sugestões únicas mostrar
  final int _maxSuggestions = 5;

  @override
  void initState() {
    super.initState();
    _futureSuggestions = _gerarTodasCombinacoes(widget.future);
  }

  Future<List<MultiplaSuggestion>> _gerarTodasCombinacoes(
      Future<List<FixturePrediction>> future,
      ) async {
    final lista = await future;
    final agora = DateTime.now();
    final allLegs = <_EntradaMultipla>[];

    // 1) Monta lista com todas as pernas possíveis
    for (final m in lista) {
      if (m.date.isBefore(agora)) continue;

      final homePct = m.homePct;
      final awayPct = m.awayPct;
      final drawPct = (100 - homePct - awayPct).clamp(0, 100).toDouble();

      // Casa / Empate / Fora sempre disponíveis
      allLegs.add(_EntradaMultipla("${m.home} x ${m.away}", "Casa vence", homePct));
      allLegs.add(_EntradaMultipla("${m.home} x ${m.away}", "Empate",    drawPct));
      allLegs.add(_EntradaMultipla("${m.home} x ${m.away}", "Fora vence", awayPct));

      // Estratégias extras com prob >= threshold
      if ((m.doubleChance ?? '').isNotEmpty && m.doubleChancePct >= _extraThreshold) {
        allLegs.add(_EntradaMultipla("${m.home} x ${m.away}", "Dupla Chance", m.doubleChancePct));
      }
      if ((m.over25Label ?? '').isNotEmpty && (m.over25Pct ?? 0) >= _extraThreshold) {
        allLegs.add(_EntradaMultipla("${m.home} x ${m.away}", "Over 2.5", m.over25Pct!.toDouble()));
      }
      if ((m.under25Label ?? '').isNotEmpty && (m.under25Pct ?? 0) >= _extraThreshold) {
        allLegs.add(_EntradaMultipla("${m.home} x ${m.away}", "Under 2.5", m.under25Pct!.toDouble()));
      }
      if ((m.ambosMarcamLabel ?? '').isNotEmpty && (m.ambosMarcamPct ?? 0) >= _extraThreshold) {
        allLegs.add(_EntradaMultipla("${m.home} x ${m.away}", "Ambas Marcam", m.ambosMarcamPct!.toDouble()));
      }
    }

    // Função de combinações
    List<List<T>> combinations<T>(List<T> list, int k) {
      if (k == 0) return [[]];
      if (list.length < k) return [];
      final result = <List<T>>[];
      for (var i = 0; i <= list.length - k; i++) {
        final head = list[i];
        for (var tail in combinations(list.sublist(i + 1), k - 1)) {
          result.add([head, ...tail]);
        }
      }
      return result;
    }

    // 2) Gera todas as duplas, triplas e múltiplas
    final combos = <MultiplaSuggestion>[];
    for (var k in [2, 3, 4]) {
      for (var legs in combinations(allLegs, k)) {
        // evita repetir o mesmo jogo em uma combinação
        final partidas = legs.map((e) => e.partida).toSet();
        if (partidas.length < k) continue;

        final odds = legs.map((e) => _probToOdd(e.prob)).toList();
        final oddTotal = odds.fold(1.0, (a, b) => a * b);
        final probTotal = legs.map((e) => e.prob / 100).fold(1.0, (a, b) => a * b) * 100;

        combos.add(MultiplaSuggestion(legs: legs, odd: oddTotal, prob: probTotal));
      }
    }

    // ordena por probabilidade descendente
    combos.sort((a, b) => b.prob.compareTo(a.prob));

    // 3) Filtra para não repetir pernas entre sugestões
    final filtered = <MultiplaSuggestion>[];
    final usedKeys = <String>{};

    String keyOf(_EntradaMultipla leg) => "${leg.partida}|${leg.tipo}";

    for (var s in combos) {
      // se alguma perna dessa sugestão já foi usada, pula
      final overlap = s.legs.any((leg) => usedKeys.contains(keyOf(leg)));
      if (overlap) continue;
      // adiciona e marca pernas como usadas
      filtered.add(s);
      for (var leg in s.legs) {
        usedKeys.add(keyOf(leg));
      }
      if (filtered.length >= _maxSuggestions) break;
    }

    return filtered;
  }

  double _probToOdd(double prob) {
    final p = prob / 100;
    return p > 0 ? (1 / p).clamp(1.01, 10.0).toDouble() : 1.01;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MultiplaSuggestion>>(
      future: _futureSuggestions,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text("Erro: ${snap.error}"));
        }

        final lista = snap.data!;
        if (lista.isEmpty) {
          return const Center(child: Text("Nenhuma múltipla disponível."));
        }

        return ListView.builder(
          itemCount: lista.length,
          itemBuilder: (_, i) {
            final m = lista[i];
            final tipo = m.legs.length == 2
                ? "Dupla"
                : m.legs.length == 3
                ? "Tripla"
                : "Múltipla";
            final cor = m.prob >= 55
                ? Colors.green.shade800
                : m.prob >= 40
                ? Colors.orange.shade700
                : Colors.red.shade700;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "🎯 $tipo • Prob: ${m.prob.toStringAsFixed(1)}% • Odd: ${m.odd.toStringAsFixed(2)}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: cor),
                    ),
                    const SizedBox(height: 8),
                    ...m.legs.map((e) => Text(
                      "⚽ ${e.partida} – ${e.tipo} (${e.prob.toStringAsFixed(1)}%)",
                    )),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text("Enviar $tipo"),
                      onPressed: () => _enviarMultipla(m, tipo),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _enviarMultipla(MultiplaSuggestion m, String tipo) {
    final buf = StringBuffer()
      ..writeln("🔥 *BotFut – $tipo do Dia* 🔥\n");
    for (final e in m.legs) {
      buf.writeln("⚽ ${e.partida}");
      buf.writeln("📌 ${e.tipo} – ${e.prob.toStringAsFixed(1)}%");
      buf.writeln("");
    }
    buf.writeln("📈 Odd: 💰 ${m.odd.toStringAsFixed(2)}");
    buf.writeln("🎲 Prob Estimada: ${m.prob.toStringAsFixed(1)}%");
    TelegramService.sendMessage(buf.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Múltipla enviada!")),
    );
  }
}

class _EntradaMultipla {
  final String partida;
  final String tipo;
  final double prob;

  _EntradaMultipla(this.partida, this.tipo, this.prob);
}

class MultiplaSuggestion {
  final List<_EntradaMultipla> legs;
  final double odd;
  final double prob;

  MultiplaSuggestion({
    required this.legs,
    required this.odd,
    required this.prob,
  });
}
