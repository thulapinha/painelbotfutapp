// lib/pages/multiplas/multipla_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/telegram_service.dart';
import 'multipla_model.dart';

class MultiplaCard extends StatelessWidget {
  final MultiplaSuggestion sugestao;
  const MultiplaCard({required this.sugestao, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tipo = sugestao.legs.length == 2
        ? "Dupla"
        : sugestao.legs.length == 3
        ? "Tripla"
        : sugestao.legs.length == 4
        ? "Quádrupla"
        : sugestao.legs.length == 5
        ? "Quíntupla"
        : sugestao.legs.length == 6
        ? "Sêxtupla"
        : "${sugestao.legs.length}-leg";

    final cor = sugestao.prob >= 75
        ? Colors.green.shade800
        : sugestao.prob >= 60
        ? Colors.orange.shade700
        : Colors.red.shade700;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            "🎯 $tipo • Probabilidade: ${sugestao.prob.toStringAsFixed(1)}% • Odd Estimada: ${sugestao.odd.toStringAsFixed(2)}",
            style: TextStyle(fontWeight: FontWeight.bold, color: cor),
          ),
          const SizedBox(height: 8),

          // Perna a perna
          ...sugestao.legs.map((e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "⚽ ${e.partida} – ${e.tipo} (${e.prob.toStringAsFixed(1)}%)",
              ),
              TextButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Abrir na Bet365"),
                onPressed: () => launchUrl(Uri.parse(e.link)),
              ),
              const SizedBox(height: 6),
            ],
          )),

          // Botão enviar
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: Text("Enviar $tipo"),
            onPressed: () => _enviarMultipla(sugestao, tipo, context),
          ),
        ]),
      ),
    );
  }

  void _enviarMultipla(MultiplaSuggestion m, String tipo, BuildContext context) {
    final buf = StringBuffer()..writeln("🔥 *BotFut – $tipo do Dia* 🔥\n");

    for (final e in m.legs) {
      buf.writeln("⚽ ${e.partida}");
      buf.writeln("📌 Estratégia: ${e.tipo}");
      buf.writeln("🔢 Confiança: ${e.prob.toStringAsFixed(1)}%");
      buf.writeln("[🔗 Ver mercado](${e.link})\n");
    }

    buf.writeln("📈 Odd Estimada: 💰 ${m.odd.toStringAsFixed(2)}");
    buf.writeln("🎲 Probabilidade Total: ${m.prob.toStringAsFixed(1)}%");

    TelegramService.sendMarkdownMessage(buf.toString(), disablePreview: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Múltipla enviada ao Telegram!")),
    );
  }
}
