import '../models/fixture_prediction.dart';

class EntradaSugestao {
  final String label;
  final double pct;
  EntradaSugestao(this.label, this.pct);
}

EntradaSugestao getMelhorSugestao(FixturePrediction m) {
  final op = <EntradaSugestao>[];

  if (m.doubleChance.isNotEmpty && m.doubleChancePct > 0) {
    op.add(EntradaSugestao("Dupla Chance: ${m.doubleChance}", m.doubleChancePct));
  }
  if (m.over25Label != null && m.over25Pct != null && m.over25Pct! > 0) {
    op.add(EntradaSugestao("Over 2.5", m.over25Pct!));
  }
  if (m.under25Label != null && m.under25Pct != null && m.under25Pct! > 0) {
    op.add(EntradaSugestao("Under 2.5", m.under25Pct!));
  }
  if (m.over15 > 0) {
    op.add(EntradaSugestao("Over 1.5", m.over15));
  }
  if (m.ambosMarcamLabel != null && m.ambosMarcamPct != null && m.ambosMarcamPct! > 0) {
    op.add(EntradaSugestao("Ambas Marcam", m.ambosMarcamPct!));
  }

  if (m.homePct > 0) op.add(EntradaSugestao("Casa vence", m.homePct));
  if (m.awayPct > 0) op.add(EntradaSugestao("Fora vence", m.awayPct));
  op.add(EntradaSugestao("Empate", (100 - m.homePct - m.awayPct).clamp(0, 100).toDouble()));

  op.sort((a, b) => b.pct.compareTo(a.pct));
  return op.first;
}

double simularConfianca(FixturePrediction m) {
  double score = 0;

  score += m.advicePct >= 50 ? m.advicePct * 0.6 : m.advicePct * 0.3;

  final xgTotal = m.xgHome + m.xgAway;
  if (xgTotal >= 2.5) score += 10;
  else if (xgTotal >= 1.8) score += 5;

  if (m.over15 >= 70) score += 10;
  else if (m.over15 >= 55) score += 5;

  if (m.doubleChancePct >= 70) score += 10;
  else if (m.doubleChancePct >= 60) score += 5;

  if ((m.homePct - m.awayPct).abs() <= 20) score += 5;

  return score.clamp(0, 100);
}

String validarTip({
  required String estrategia,
  required int golsCasa,
  required int golsFora,
  required String nomeCasa,
  required String nomeFora,
}) {
  final lower = estrategia.toLowerCase();
  final totalGols = golsCasa + golsFora;

  if (lower.contains("empate") && !lower.contains("ou") && golsCasa == golsFora) {
    return "GREEN";
  }

  if (lower.contains("casa vence") || lower.contains(nomeCasa.toLowerCase())) {
    return golsCasa > golsFora ? "GREEN" : "RED";
  }

  if (lower.contains("fora vence") || lower.contains(nomeFora.toLowerCase())) {
    return golsFora > golsCasa ? "GREEN" : "RED";
  }

  if (lower.contains("dupla chance")) {
    final partes = lower.split("dupla chance:").last.trim().split("ou");
    final op1 = partes[0].trim();
    final op2 = partes.length > 1 ? partes[1].trim() : "";

    bool condicao(String op) =>
        (op == nomeCasa.toLowerCase() && golsCasa > golsFora) ||
            (op == nomeFora.toLowerCase() && golsFora > golsCasa) ||
            (op == "empate" && golsCasa == golsFora);

    return (condicao(op1) || condicao(op2)) ? "GREEN" : "RED";
  }

  if (lower.contains("over 1.5")) return totalGols > 1 ? "GREEN" : "RED";
  if (lower.contains("over 2.5")) return totalGols > 2 ? "GREEN" : "RED";
  if (lower.contains("under 2.5")) return totalGols < 3 ? "GREEN" : "RED";

  if (lower.contains("ambas marcam") || lower.contains("ambos marcam")) {
    return (golsCasa > 0 && golsFora > 0) ? "GREEN" : "RED";
  }

  return "VOID";
}
