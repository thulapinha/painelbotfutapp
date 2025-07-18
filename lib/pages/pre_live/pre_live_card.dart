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
    } catch (_) {}
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

  String traduzirTip(String raw) {
    return raw
        .replaceAll("Combo", "Combo")
        .replaceAll("Double chance", "Dupla Chance")
        .replaceAll("Win or draw", "Vitória ou Empate")
        .replaceAll("draw or", "Empate ou")
        .replaceAll("or draw", "ou Empate")
        .replaceAll("or", "ou")
        .replaceAll("+2.5 goals", "Mais de 2.5 Gols")
        .replaceAll("+1.5 goals", "Mais de 1.5 Gols")
        .replaceAll("-2.5 goals", "Menos de 2.5 Gols")
        .replaceAll("goals", "Gols")
        .replaceAll(" and ", " e ");
  }

  String traduzirEstrategia(String raw) {
    return raw
        .replaceAll("Double Chance", "Dupla Chance")
        .replaceAll("Win or draw", "Vitória ou Empate")
        .replaceAll("Draw", "Empate")
        .replaceAll("Win", "Vitória")
        .replaceAll("Over 2.5", "Mais de 2.5")
        .replaceAll("Over 1.5", "Mais de 1.5")
        .replaceAll("Under 2.5", "Menos de 2.5")
        .replaceAll("Both teams score", "Ambas Marcam");
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.jogo;
    final dt = j.date;
    final date = '${dt.day}/${dt.month}/${dt.year}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final statusIcon = j.date.isBefore(DateTime.now()) ? '⏱️' : '🟢';

    final best = getMelhorSugestao(j);
    final rawTip = j.advice;
    final tipPct = j.advicePct;

    final principalLabel = (rawTip.isNotEmpty && tipPct >= best.pct)
        ? traduzirTip(rawTip)
        : traduzirEstrategia(best.label);
    final principalPct = (rawTip.isNotEmpty && tipPct >= best.pct)
        ? tipPct
        : best.pct;
    final corPrincipal = _getCor(principalPct);

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

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, color: corPrincipal, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '📌 $principalLabel – ${principalPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: corPrincipal,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, color: corSimulada, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '🔮 Confiança simulada: ${simulada.toStringAsFixed(1)}%',
                    style: TextStyle(color: corSimulada),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Enviar tip"),
              onPressed: widget.onEnviar ??
                      () {
                    final buf = StringBuffer()
                      ..writeln("🎯 *BotFut – Tip*")
                      ..writeln("⚽ ${j.home} x ${j.away}")
                      ..writeln("📅 $date ⏰ $time")
                      ..writeln("📌 $principalLabel")
                      ..writeln("🔢 Confiança: ${principalPct.toStringAsFixed(1)}%")
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

  Color _getCor(double pct) {
    if (pct >= 80) return Colors.green.shade800;
    if (pct >= 65) return Colors.orange.shade700;
    return Colors.grey.shade600;
  }
}
