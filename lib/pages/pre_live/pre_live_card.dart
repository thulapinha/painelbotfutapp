import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:diacritic/diacritic.dart';

import '../../models/fixture_prediction.dart';
import '../../services/telegram_service.dart';
import '../../services/radar_service.dart';
import '../../utils/estrategia_util.dart';

class PreLiveCard extends StatefulWidget {
  final FixturePrediction jogo;
  final bool mostrarHora;
  final void Function()? onEnviar;

  const PreLiveCard({
    required this.jogo,
    this.mostrarHora = true,
    this.onEnviar,
    Key? key,
  }) : super(key: key);

  @override
  State<PreLiveCard> createState() => _PreLiveCardState();
}

class _PreLiveCardState extends State<PreLiveCard> {
  String? _radarLink;
  late final String _fallbackLink;

  @override
  void initState() {
    super.initState();
    _fallbackLink = _generateFallbackLink(widget.jogo);
    _loadRadarLink();
  }

  Future<void> _loadRadarLink() async {
    final home = widget.jogo.home.trim();
    final away = widget.jogo.away.trim();
    final termo = '$home $away';

    try {
      final link = await RadarService.obterLinkBet365(
        termo: termo,
        fixtureDate: widget.jogo.date,
        home: home,
        away: away,
      );
      setState(() => _radarLink = link);
    } catch (_) {
      // falha silenciosa
    }
  }

  String _generateFallbackLink(FixturePrediction j) {
    var termo = '${j.home} ${j.away}';
    termo = termo.replaceAll(RegExp(r'[\(\)_]'), ' ');
    termo = removeDiacritics(termo).trim();
    termo = termo.replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ');
    termo = termo.replaceAll(RegExp(r'\s+'), ' ').trim();
    final encoded = Uri.encodeComponent(termo);
    return 'https://bet365.bet.br/#/AX/K^$encoded/';
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.jogo;
    final dt = j.date;
    final date = '${dt.day}/${dt.month}/${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final statusIcon = j.date.isBefore(DateTime.now()) ? '⏱️' : '🟢';

    final best = getMelhorSugestao(j);
    final corBest = _getCor(best.pct);

    final advice = j.advice;
    final advicePct = _getPctByLabel(j, advice);
    final corAdvice = _getCor(advicePct);

    final simulada = simularConfianca(j);
    final corSimulada = _getCor(simulada);

    final bet365Url = _radarLink ?? _fallbackLink;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$statusIcon ${j.home} x ${j.away}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.mostrarHora) ...[
              const SizedBox(height: 4),
              Text('📅 $date    ⏰ $time'),
            ],
            const SizedBox(height: 8),

            Row(children: [
              Icon(Icons.circle, color: corBest, size: 12),
              const SizedBox(width: 6),
              Text(
                '📌 ${best.label} – ${best.pct.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: corBest),
              ),
            ]),

            if (advice.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.circle, color: corAdvice, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '🧠 $advice – ${advicePct.toStringAsFixed(1)}%',
                    style: TextStyle(color: corAdvice),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.circle, color: corSimulada, size: 12),
              const SizedBox(width: 6),
              Text(
                '🔮 Confiança simulada: ${simulada.toStringAsFixed(1)}%',
                style: TextStyle(color: corSimulada),
              ),
            ]),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Enviar tip"),
              onPressed: widget.onEnviar ?? () {
                final jogo = widget.jogo;
                final dt = jogo.date;
                final date = "${dt.day}/${dt.month}/${dt.year}";
                final time = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                final best = getMelhorSugestao(jogo);
                final advice = jogo.advice;
                final advicePct = _getPctByLabel(jogo, advice);
                final simulada = simularConfianca(jogo);
                final bet365Url = _radarLink ?? _fallbackLink;

                final buf = StringBuffer()
                  ..writeln("🎯 *BotFut – Tip*")
                  ..writeln("⚽ ${jogo.home} x ${jogo.away}")
                  ..writeln("📅 $date ⏰ $time")
                  ..writeln("📌 Estratégia: ${best.label}")
                  ..writeln("🔢 Confiança: ${best.pct.toStringAsFixed(1)}%");

                if (advice.isNotEmpty && advicePct > 0) {
                  buf
                    ..writeln("")
                    ..writeln("🧠 Dica: $advice")
                    ..writeln("🔢 Confiança da dica: ${advicePct.toStringAsFixed(1)}%");
                }

                buf
                  ..writeln("")
                  ..writeln("🔮 Confiança simulada: ${simulada.toStringAsFixed(1)}%")
                  ..writeln("[🔗 Abrir no Bet365]($bet365Url)");

                TelegramService.sendMarkdownMessage(
                  buf.toString(),
                  disablePreview: true,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tip enviada ao Telegram!")),
                );
              },
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Abrir no Bet365'),
              onPressed: () => _abrirUrl(bet365Url),
            ),
          ],
        ),
      ),
    );
  }

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
    if (label.toLowerCase().contains('casa vence')) return m.homePct;
    if (label.toLowerCase().contains('fora vence')) return m.awayPct;
    if (label.toLowerCase().contains('empate')) {
      return (100 - m.homePct - m.awayPct).clamp(0, 100).toDouble();
    }
    return 0;
  }

  Color _getCor(double pct) {
    if (pct >= 80) return Colors.green.shade800;
    if (pct >= 65) return Colors.orange.shade700;
    return Colors.grey.shade600;
  }
}
