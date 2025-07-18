import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeGoals;
  final int awayGoals;
  final String prediction;
  final double confidence;
  final String status;               // GREEN, RED ou VOID
  final String? secondaryPrediction; // texto da dica secundária
  final String? secondaryStatus;     // MEIO ou VOID

  const ReportCard({
    Key? key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeGoals,
    required this.awayGoals,
    required this.prediction,
    required this.confidence,
    required this.status,
    this.secondaryPrediction,
    this.secondaryStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // cores e rótulos do status principal
    Color mainColor;
    String mainLabel;
    switch (status) {
      case 'GREEN':
        mainColor = Colors.green.shade700;
        mainLabel = 'ACERTOU';
        break;
      case 'RED':
        mainColor = Colors.red.shade700;
        mainLabel = 'ERROU';
        break;
      default:
        mainColor = Colors.grey.shade600;
        mainLabel = 'VOID';
    }

    // cores e rótulos da dica secundária
    Color secColor = Colors.grey.shade600;
    String secLabel = 'VOID';
    if (secondaryStatus == 'MEIO') {
      secColor = Colors.amber.shade700;
      secLabel = 'MEIO';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: mainColor, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ✅ Header: times + status principal
          Row(children: [
            Expanded(
              child: Text(
                '$homeTeam  x  $awayTeam',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                mainLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              backgroundColor: mainColor,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),

          const SizedBox(height: 8),

          // 🎯 Placar + confiança
          Row(children: [
            Expanded(
              child: Text(
                'Resultado: $homeGoals – $awayGoals',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${confidence.toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ),
            ),
          ]),

          // 🔸 Dica principal
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lightbulb_outline, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                prediction,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ]),

          // 🔹 Dica secundária (se houver)
          if (secondaryPrediction?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.subdirectory_arrow_right, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  secondaryPrediction!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  secLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                backgroundColor: secColor,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
