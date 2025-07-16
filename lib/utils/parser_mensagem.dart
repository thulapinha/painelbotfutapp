class MensagemCorner {
  final String timeA;
  final String timeB;
  final String competencia;
  final String minuto;
  final String score;
  final String urlCorner;
  final String urlCasaAposta;

  MensagemCorner({
    required this.timeA,
    required this.timeB,
    required this.competencia,
    required this.minuto,
    required this.score,
    required this.urlCorner,
    required this.urlCasaAposta,
  });
}

MensagemCorner? extrairCornerProbet(String texto) {
  try {
    final linhas = texto.split('\n');
    String timeA = '', timeB = '', competencia = '', minuto = '', score = '', urlCorner = '', urlAposta = '';

    for (final linha in linhas) {
      if (linha.contains("x")) {
        final partes = linha.split('x');
        timeA = partes[0].split(':').last.trim();
        timeB = partes[1].trim();
      }

      if (linha.toLowerCase().contains("competição") || linha.toLowerCase().contains("competicao")) {
        competencia = linha.split(':').last.trim();
      }

      if (linha.contains("Tempo:")) minuto = linha.split(':').last.trim();
      if (linha.contains("Resultado:")) score = linha.split(':').last.trim();
      if (linha.contains("https://cornerprobet.com/analysis/")) urlCorner = linha.trim();
      if (linha.contains("https://bet")) urlAposta = linha.trim();
    }

    return MensagemCorner(
      timeA: timeA,
      timeB: timeB,
      competencia: competencia,
      minuto: minuto,
      score: score,
      urlCorner: urlCorner,
      urlCasaAposta: urlAposta,
    );
  } catch (_) {
    return null;
  }
}
