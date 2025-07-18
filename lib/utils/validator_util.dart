/// lib/utils/validator_util.dart
///
/// Validador de estratégias: compara dica com resultado real
/// Retorna 'GREEN' se acertou, 'RED' se errou e 'VOID' se não reconheceu.

String validarTip({
  required String estrategia,
  required int golsCasa,
  required int golsFora,
  required String nomeCasa,
  required String nomeFora,
}) {
  final lower = estrategia
      .toLowerCase()
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .trim();
  final totalGols = golsCasa + golsFora;
  final casa = nomeCasa.toLowerCase();
  final fora = nomeFora.toLowerCase();

  // 1) Combo genérico (tratamento especial para DC + OU)
  if (lower.startsWith('combo')) {
    // remove apenas "combo" e preserva o resto, ex: "double chance: ... and +1.5 goals"
    final raw = lower.substring(5).trim();
    final parts = raw.split(RegExp(r'\s+and\s+')).map((p) => p.trim()).toList();

    // calcula status de cada sub-strategy
    final statuses = parts.map((p) {
      return validarTip(
        estrategia: p,
        golsCasa: golsCasa,
        golsFora: golsFora,
        nomeCasa: nomeCasa,
        nomeFora: nomeFora,
      );
    }).toList();

    // identifica se misturou Double Chance e Over/Under
    final hasDC = parts.any((p) =>
    p.contains('double chance') || p.contains('dupla chance'));
    final hasOU = parts.any((p) =>
    p.contains('over') ||
        p.contains('+') ||
        p.contains('mais de') ||
        p.contains('-') ||
        p.contains('menos de'));

    // se for DC+OU, basta 1 GREEN (OR)
    if (hasDC && hasOU) {
      String dcStatus = 'RED', ouStatus = 'RED';
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].contains('double chance') ||
            parts[i].contains('dupla chance')) {
          dcStatus = statuses[i];
        }
        if (parts[i].contains('over') ||
            parts[i].contains('+') ||
            parts[i].contains('mais de') ||
            parts[i].contains('-') ||
            parts[i].contains('menos de')) {
          ouStatus = statuses[i];
        }
      }
      return (dcStatus == 'GREEN' || ouStatus == 'GREEN') ? 'GREEN' : 'RED';
    }

    // caso contrário, exige todos os sub-itens como GREEN (AND)
    return statuses.every((s) => s == 'GREEN') ? 'GREEN' : 'RED';
  }

  // 2) Double Chance / Dupla Chance
  if (lower.contains('double chance') || lower.contains('dupla chance')) {
    final rule = lower.split(':').length > 1 ? lower.split(':')[1] : '';
    final ops = rule
        .split(RegExp(r'\s+or\s+|\s+ou\s+'))
        .map((p) => p.trim());
    final winCasa = golsCasa > golsFora;
    final winFora = golsFora > golsCasa;
    final draw = golsCasa == golsFora;
    for (var op in ops) {
      if ((op == casa && winCasa) ||
          (op == fora && winFora) ||
          (op == 'empate' && draw) ||
          (op == 'draw' && draw)) {
        return 'GREEN';
      }
    }
    return 'RED';
  }

  // 3) Ambas marcam / Both teams to score
  if (lower.contains('ambas marcam') ||
      lower.contains('ambos marcam') ||
      lower.contains('both teams to score')) {
    return (golsCasa > 0 && golsFora > 0) ? 'GREEN' : 'RED';
  }

  // 4) Over/Under dinâmico (+X.X / -X.X ou "mais de"/"menos de")
  final rePlusMinus = RegExp(r'([+-])\s*(\d+(?:\.\d+)?)');
  final rePt = RegExp(r'(mais de|menos de)\s*(\d+(?:\.\d+)?)');
  var m = rePlusMinus.firstMatch(lower);
  if (m != null) {
    final sign = m.group(1);
    final thr = double.parse(m.group(2)!);
    if (sign == '+') return totalGols > thr ? 'GREEN' : 'RED';
    if (sign == '-') return totalGols < thr ? 'GREEN' : 'RED';
  }
  m = rePt.firstMatch(lower);
  if (m != null) {
    final dir = m.group(1);
    final thr = double.parse(m.group(2)!);
    if (dir == 'mais de') return totalGols > thr ? 'GREEN' : 'RED';
    if (dir == 'menos de') return totalGols < thr ? 'GREEN' : 'RED';
  }

  // 5) Empate simples
  if (lower == 'empate' || lower == 'draw') {
    return golsCasa == golsFora ? 'GREEN' : 'RED';
  }

  // 6) Vitória simples (Casa/Fora vence)
  if (lower.contains('casa vence') ||
      lower.contains('home wins') ||
      lower == casa) {
    return golsCasa > golsFora ? 'GREEN' : 'RED';
  }
  if (lower.contains('fora vence') ||
      lower.contains('away wins') ||
      lower == fora) {
    return golsFora > golsCasa ? 'GREEN' : 'RED';
  }

  // não reconhecido
  return 'VOID';
}
