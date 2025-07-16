class EntradaMultipla {
  final String partida;
  final String tipo;
  final double prob;
  final String link;

  EntradaMultipla(this.partida, this.tipo, this.prob, this.link);
}

class MultiplaSuggestion {
  final List<EntradaMultipla> legs;
  final double odd;
  final double prob;

  MultiplaSuggestion({required this.legs, required this.odd, required this.prob});
}
