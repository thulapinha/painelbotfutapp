import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeGoals;
  final int awayGoals;
  final String prediction;
  final double confidence; // ex: 50.0
  final String status;     // GREEN, RED ou VOID

  const ReportCard({
    Key? key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeGoals,
    required this.awayGoals,
    required this.prediction,
    required this.confidence,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case 'GREEN':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'RED':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '$homeTeam vs $awayTeam',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Dica: $prediction (${confidence.toStringAsFixed(0)}%)'),
          const SizedBox(height: 4),
          Text('Resultado: $homeGoals – $awayGoals'),
          const SizedBox(height: 8),
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 6),
            Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }
}
