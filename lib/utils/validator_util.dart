/// Validador de tips: compara estratégia sugerida com resultado real
/// Retorna 'GREEN' se a entrada bateu, 'RED' se falhou, 'VOID' se não pode validar

String validarTip({
  required String estrategia,
  required int golsCasa,
  required int golsFora,
  required String nomeCasa,
  required String nomeFora,
}) {
  final lower = estrategia.toLowerCase();
  final totalGols = golsCasa + golsFora;

  // ⛳ Empate
  if (lower.contains("empate") && !lower.contains("ou") && golsCasa == golsFora) {
    return "GREEN";
  }

  // 🏠 Casa vence
  if (lower.contains("casa vence") || lower.contains(nomeCasa.toLowerCase())) {
    return golsCasa > golsFora ? "GREEN" : "RED";
  }

  // 🚶‍♂️ Fora vence
  if (lower.contains("fora vence") || lower.contains(nomeFora.toLowerCase())) {
    return golsFora > golsCasa ? "GREEN" : "RED";
  }

  // 🎯 Dupla Chance
  if (lower.contains("dupla chance")) {
    final partes = lower.split("dupla chance:").last.trim().split("ou");
    final op1 = partes[0].trim();
    final op2 = partes.length > 1 ? partes[1].trim() : "";

    final cond1 = (op1 == nomeCasa.toLowerCase() && golsCasa > golsFora) ||
        (op1 == nomeFora.toLowerCase() && golsFora > golsCasa) ||
        (op1 == "empate" && golsCasa == golsFora);

    final cond2 = (op2 == nomeCasa.toLowerCase() && golsCasa > golsFora) ||
        (op2 == nomeFora.toLowerCase() && golsFora > golsCasa) ||
        (op2 == "empate" && golsCasa == golsFora);

    return (cond1 || cond2) ? "GREEN" : "RED";
  }

  // ⚽ Over/Under
  if (lower.contains("over 1.5")) return totalGols > 1 ? "GREEN" : "RED";
  if (lower.contains("over 2.5")) return totalGols > 2 ? "GREEN" : "RED";
  if (lower.contains("under 2.5")) return totalGols < 3 ? "GREEN" : "RED";

  // 🔥 Ambas marcam
  if (lower.contains("ambas marcam") || lower.contains("ambos marcam")) {
    return (golsCasa > 0 && golsFora > 0) ? "GREEN" : "RED";
  }

  // ❓ Não reconhecido
  return "VOID";
}
