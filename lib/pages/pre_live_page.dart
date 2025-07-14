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

  void _refreshNow() {
    setState(() {
      _future = widget.future;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final agora = DateTime.now();

    return Column(
      children: [
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
              final list = _mostrarSomenteFuturos
                  ? todos.where((m) => m.date.isAfter(agora)).toList()
                  : todos;

              if (list.isEmpty) {
                return const Center(child: Text('Nenhum jogo encontrado.'));
              }

              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final m = list[i];
                  final dt = m.date;
                  final date = "${dt.day}/${dt.month}/${dt.year}";
                  final time =
                      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                  final melhor = _getMelhorEntrada(m);
                  final destaqueCor = melhor.pct >= 80
                      ? Colors.green.shade800
                      : melhor.pct >= 65
                      ? Colors.orange.shade700
                      : Colors.grey.shade700;

                  final isPassado = m.date.isBefore(agora);
                  final statusIcon = isPassado ? "⏱️" : "🟢";

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text("$statusIcon ${m.home} x ${m.away}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📅 $date    ⏰ $time"),
                          const SizedBox(height: 6),
                          Text(
                            "📌 Estratégia: ${melhor.label}",
                            style: TextStyle(
                              color: destaqueCor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (m.advice.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "🧠 ${m.advice}",
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.send),
                        tooltip: "Enviar tip",
                        onPressed: () => _enviarTip(m, melhor),
                      ),
                      onTap: () => _mostrarDialogo(m, melhor),
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

  void _enviarTip(FixturePrediction m, _EntradaSugestao melhor) {
    final dt = m.date;
    final date = "${dt.day}/${dt.month}/${dt.year}";
    final time =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    final msg =
        """
🎯 *BotFut – Tip*
⚽ ${m.home} x ${m.away}
📅 $date ⏰ $time
📌 Estratégia: ${melhor.label}
${m.advice.isNotEmpty ? "🧠 ${m.advice}" : ""}
""";
    TelegramService.sendMessage(msg);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Tip enviada ao Telegram!")));
  }

  void _mostrarDialogo(FixturePrediction m, _EntradaSugestao melhor) {
    final dt = m.date;
    final date = "${dt.day}/${dt.month}/${dt.year}";
    final time =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    final msg =
        """
🎯 *BotFut – Tip*
⚽ ${m.home} x ${m.away}
📅 $date ⏰ $time
📌 Estratégia: ${melhor.label}
${m.advice.isNotEmpty ? "🧠 ${m.advice}" : ""}
""";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("🔮 ${melhor.label}"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text("Enviar Telegram"),
            onPressed: () {
              Navigator.pop(context);
              TelegramService.sendMessage(msg);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tip enviada ao Telegram!")),
              );
            },
          ),
        ],
      ),
    );
  }

  _EntradaSugestao _getMelhorEntrada(FixturePrediction m) {
    final List<_EntradaSugestao> opcoes = [];

    if ((m.doubleChance ?? '').isNotEmpty && m.doubleChancePct > 70) {
      opcoes.add(
        _EntradaSugestao("Dupla Chance: ${m.doubleChance}", m.doubleChancePct),
      );
    }

    if ((m.over25Label ?? '').isNotEmpty && (m.over25Pct ?? 0) > 70) {
      opcoes.add(_EntradaSugestao("Over 2.5", m.over25Pct!));
    }

    if ((m.under25Label ?? '').isNotEmpty && (m.under25Pct ?? 0) > 70) {
      opcoes.add(_EntradaSugestao("Under 2.5", m.under25Pct!));
    }

    if (m.over15 > 70) {
      opcoes.add(_EntradaSugestao("Over 1.5", m.over15));
    }

    if ((m.ambosMarcamLabel ?? '').isNotEmpty && (m.ambosMarcamPct ?? 0) > 70) {
      opcoes.add(_EntradaSugestao("Ambas Marcam", m.ambosMarcamPct!));
    }

    if (m.homePct > 70) {
      opcoes.add(_EntradaSugestao("Casa vence", m.homePct));
    }

    if (m.awayPct > 70) {
      opcoes.add(_EntradaSugestao("Fora vence", m.awayPct));
    }

    // Se nada passou dos 70%, usa fallback com base nas melhores disponíveis
    if (opcoes.isEmpty) {
      final fallback = <_EntradaSugestao>[
        if ((m.doubleChance ?? '').isNotEmpty)
          _EntradaSugestao(
            "Dupla Chance: ${m.doubleChance}",
            m.doubleChancePct,
          ),
        if ((m.over25Label ?? '').isNotEmpty)
          _EntradaSugestao("Over 2.5", m.over25Pct ?? 0),
        if ((m.under25Label ?? '').isNotEmpty)
          _EntradaSugestao("Under 2.5", m.under25Pct ?? 0),
        if (m.over15 > 0) _EntradaSugestao("Over 1.5", m.over15),
        if ((m.ambosMarcamLabel ?? '').isNotEmpty)
          _EntradaSugestao("Ambas Marcam", m.ambosMarcamPct ?? 0),
        _EntradaSugestao("Casa vence", m.homePct),
        _EntradaSugestao("Fora vence", m.awayPct),
      ];

      fallback.sort((a, b) => b.pct.compareTo(a.pct));
      return fallback.first;
    }

    opcoes.sort((a, b) => b.pct.compareTo(a.pct));
    return opcoes.first;
  }

  @override
  bool get wantKeepAlive => true;
}

class _EntradaSugestao {
  final String label;
  final double pct;
  _EntradaSugestao(this.label, this.pct);
}
