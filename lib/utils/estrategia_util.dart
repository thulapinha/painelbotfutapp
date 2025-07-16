import '../models/fixture_prediction.dart';

class EntradaSugestao {
  final String label;
  final double pct;
  EntradaSugestao(this.label, this.pct);
}

EntradaSugestao getMelhorSugestao(FixturePrediction m) {
  final op = <EntradaSugestao>[];

  if (m.doubleChance.isNotEmpty) {
    op.add(EntradaSugestao("Dupla Chance: ${m.doubleChance}", m.doubleChancePct));
  }
  if (m.over25Label != null && m.over25Pct != null) {
    op.add(EntradaSugestao("Over 2.5", m.over25Pct!));
  }
  if (m.under25Label != null && m.under25Pct != null) {
    op.add(EntradaSugestao("Under 2.5", m.under25Pct!));
  }
  if (m.over15 > 0) {
    op.add(EntradaSugestao("Over 1.5", m.over15));
  }
  if (m.ambosMarcamLabel != null && m.ambosMarcamPct != null) {
    op.add(EntradaSugestao("Ambas Marcam", m.ambosMarcamPct!));
  }

  op.add(EntradaSugestao("Casa vence", m.homePct));
  op.add(EntradaSugestao("Empate", (100 - m.homePct - m.awayPct).clamp(0, 100).toDouble()));
  op.add(EntradaSugestao("Fora vence", m.awayPct));

  op.sort((a, b) => b.pct.compareTo(a.pct));
  return op.first;
}

double simularConfianca(FixturePrediction m) {
  double score = 0;

  if (m.advicePct >= 50) {
    score += m.advicePct * 0.6;
  } else {
    score += m.advicePct * 0.3;
  }

  final xgTotal = m.xgHome + m.xgAway;
  if (xgTotal >= 2.5) score += 10;
  else if (xgTotal >= 1.8) score += 5;

  if (m.over15 >= 70) score += 10;
  else if (m.over15 >= 55) score += 5;

  if (m.doubleChancePct >= 70) score += 10;
  else if (m.doubleChancePct >= 60) score += 5;

  final diff = (m.homePct - m.awayPct).abs();
  if (diff <= 20) score += 5;

  return score.clamp(0, 100);
}
