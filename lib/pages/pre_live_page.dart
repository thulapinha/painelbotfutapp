import 'package:flutter/material.dart';
import '../models/fixture_prediction.dart';
import '../services/telegram_service.dart';

class PreLivePage extends StatefulWidget {
  final Future<List<FixturePrediction>> future;
  const PreLivePage({required this.future, Key? key}) : super(key: key);

  @override
  State<PreLivePage> createState() => _PreLivePageState();
}

class _PreLivePageState extends State<PreLivePage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<FixturePrediction>> _future;
  bool _mostrarSomenteFuturos = false;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
  }

  void _refreshNow() => setState(() => _future = widget.future);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final agora = DateTime.now();

    return Column(
      children: [
        // Botão de refresh + filtro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Atualizar agora"),
                onPressed: _refreshNow,
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: Text(
                  _mostrarSomenteFuturos ? "Somente futuros" : "Todos os jogos",
                ),
                selected: _mostrarSomenteFuturos,
                onSelected: (v) => setState(() => _mostrarSomenteFuturos = v),
                selectedColor: Colors.green.shade100,
              ),
            ],
          ),
        ),

        // Legenda de cores
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🔎 Legenda de Confiança:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.circle, color: Colors.green.shade800, size: 12),
                    const SizedBox(width: 6),
                    const Text("Alta (≥ 80%)"),
                  ]),
                  Row(children: [
                    Icon(Icons.circle, color: Colors.orange.shade700, size: 12),
                    const SizedBox(width: 6),
                    const Text("Moderada (65–79%)"),
                  ]),
                  Row(children: [
                    Icon(Icons.circle, color: Colors.grey.shade600, size: 12),
                    const SizedBox(width: 6),
                    const Text("Baixa (< 65%) – risco elevado"),
                  ]),
                ],
              ),
            ),
          ),
        ),

        // Lista de jogos
        Expanded(
          child: FutureBuilder<List<FixturePrediction>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Erro: ${snap.error}'));
              }

              final todos = snap.data ?? [];
              final jogos = _mostrarSomenteFuturos
                  ? todos.where((m) => m.date.isAfter(agora)).toList()
                  : todos;

              if (jogos.isEmpty) {
                return const Center(child: Text('Nenhum jogo encontrado.'));
              }

              return ListView.builder(
                itemCount: jogos.length,
                itemBuilder: (ctx, i) {
                  final m = jogos[i];
                  final dt = m.date;
                  final date = "${dt.day}/${dt.month}/${dt.year}";
                  final time =
                      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                  final statusIcon = m.date.isBefore(agora) ? "⏱️" : "🟢";

                  // MELHOR ESTRATÉGIA
                  final best = _getMelhorSugestao(m);
                  final corBest = _getCor(best.pct);

                  // DICA e pct derivado
                  final adviceText = m.advice;
                  final advicePct = _getPctByLabel(m, adviceText);
                  final corAdvice = _getCor(advicePct);

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cabeçalho
                            Text("$statusIcon ${m.home} x ${m.away}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("📅 $date    ⏰ $time"),
                            const SizedBox(height: 8),

                            // Melhor sugestão
                            Row(children: [
                              Icon(Icons.circle, color: corBest, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                "📌 ${best.label} – ${best.pct.toStringAsFixed(1)}%",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: corBest),
                              ),
                            ]),

                            const SizedBox(height: 6),

                            // Dica derivada
                            if (adviceText.isNotEmpty)
                              Row(children: [
                                Icon(Icons.circle,
                                    color: corAdvice, size: 12),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "🧠 $adviceText – ${advicePct.toStringAsFixed(1)}%",
                                    style: TextStyle(color: corAdvice),
                                  ),
                                )
                              ]),

                            const SizedBox(height: 10),

                            // Botão único de envio
                            ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text("Enviar tip"),
                              onPressed: () =>
                                  _enviarTip(m, best, advicePct),
                            ),
                          ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Escolhe a melhor entrada de acordo com maior pct disponível
  _EntradaSugestao _getMelhorSugestao(FixturePrediction m) {
    final op = <_EntradaSugestao>[];

    if (m.doubleChance.isNotEmpty) {
      op.add(_EntradaSugestao(
          "Dupla Chance: ${m.doubleChance}", m.doubleChancePct));
    }
    if (m.over25Label != null && m.over25Pct != null) {
      op.add(_EntradaSugestao("Over 2.5", m.over25Pct!));
    }
    if (m.under25Label != null && m.under25Pct != null) {
      op.add(_EntradaSugestao("Under 2.5", m.under25Pct!));
    }
    if (m.over15 > 0) {
      op.add(_EntradaSugestao("Over 1.5", m.over15));
    }
    if (m.ambosMarcamLabel != null && m.ambosMarcamPct != null) {
      op.add(_EntradaSugestao("Ambas Marcam", m.ambosMarcamPct!));
    }

    op.add(_EntradaSugestao("Casa vence", m.homePct));
    op.add(_EntradaSugestao("Empate",
        (100 - m.homePct - m.awayPct).clamp(0, 100).toDouble()));
    op.add(_EntradaSugestao("Fora vence", m.awayPct));

    op.sort((a, b) => b.pct.compareTo(a.pct));
    return op.first;
  }

  /// Retorna uma cor baseada na faixa de pct
  Color _getCor(double pct) {
    if (pct >= 80) return Colors.green.shade800;
    if (pct >= 65) return Colors.orange.shade700;
    return Colors.grey.shade600;
  }

  /// Busca a probabilidade associada ao texto da dica
  double _getPctByLabel(FixturePrediction m, String label) {
    if (label.contains(m.doubleChance)) return m.doubleChancePct;
    if (m.over25Label != null && label.contains(m.over25Label!)) {
      return m.over25Pct ?? 0;
    }
    if (m.under25Label != null && label.contains(m.under25Label!)) {
      return m.under25Pct ?? 0;
    }
    if (m.ambosMarcamLabel != null && label.contains(m.ambosMarcamLabel!)) {
      return m.ambosMarcamPct ?? 0;
    }
    if (label.toLowerCase().contains("casa vence")) return m.homePct;
    if (label.toLowerCase().contains("fora vence")) return m.awayPct;
    if (label.toLowerCase().contains("empate")) {
      return (100 - m.homePct - m.awayPct).clamp(0, 100).toDouble();
    }
    // fallback
    return 0;
  }

  /// Envia a tip ao Telegram
  void _enviarTip(
      FixturePrediction m, _EntradaSugestao best, double advicePct) {
    final dt = m.date;
    final date = "${dt.day}/${dt.month}/${dt.year}";
    final time =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    final buf = StringBuffer()
      ..writeln("🎯 *BotFut – Tip*")
      ..writeln("⚽ ${m.home} x ${m.away}")
      ..writeln("📅 $date ⏰ $time")
      ..writeln("📌 Estratégia: ${best.label}")
      ..writeln("🔢 Confiança: ${best.pct.toStringAsFixed(1)}%");

    final adviceText = m.advice;
    if (adviceText.isNotEmpty && advicePct > 0) {
      buf
        ..writeln("")
        ..writeln("🧠 Dica: $adviceText")
        ..writeln("🔢 Confiança da dica: ${advicePct.toStringAsFixed(1)}%");
    }

    TelegramService.sendMessage(buf.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tip enviada ao Telegram!")),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _EntradaSugestao {
  final String label;
  final double pct;
  _EntradaSugestao(this.label, this.pct);
}
