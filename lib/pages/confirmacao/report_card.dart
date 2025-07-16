import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final String estrategia;
  final String status;
  final int golsCasa;
  final int golsFora;
  final String nomeCasa;
  final String nomeFora;

  const ReportCard({
    required this.estrategia,
    required this.status,
    required this.golsCasa,
    required this.golsFora,
    required this.nomeCasa,
    required this.nomeFora,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color cor;
    IconData icone;

    switch (status) {
      case "GREEN":
        cor = Colors.green.shade800;
        icone = Icons.check_circle;
        break;
      case "RED":
        cor = Colors.red.shade700;
        icone = Icons.cancel;
        break;
      default:
        cor = Colors.grey.shade600;
        icone = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("⚽ $nomeCasa x $nomeFora",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("📌 Estratégia: $estrategia"),
            Text("📊 Resultado: $golsCasa x $golsFora"),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icone, color: cor),
                const SizedBox(width: 6),
                Text("Status: $status", style: TextStyle(color: cor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
