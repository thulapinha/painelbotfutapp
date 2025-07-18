// lib/pages/multiplas/multipla_utils.dart

import 'package:diacritic/diacritic.dart';
import '../../models/fixture_prediction.dart';
import 'multipla_model.dart';

const double DC_THRESHOLD = 65.0;  // mínimo % para Dupla Chance
const double OU_THRESHOLD = 50.0;  // mínimo % para Over/Under
const int MAX_LEGS = 16;           // máximo de pernas a considerar
const int MAX_SUGESTOES = 6;       // máximo de múltiplas resultantes

// Gera link pra Bet365
String gerarLink(FixturePrediction m) {
  var termo = '${m.home} ${m.away}';
  termo = removeDiacritics(termo)
      .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
      .trim();
  final encoded = Uri.encodeComponent(termo);
  return 'https://bet365.bet.br/#/AX/K^$encoded/';
}

// Converte probabilidade (%) em odd
double probToOdd(double p) {
  final prob = p / 100;
  if (prob <= 0) return 1.01;
  return (1 / prob).clamp(1.01, 15.0);
}

// Combinações recursivas
List<List<T>> combinations<T>(List<T> list, int k) {
  if (k == 0) return [[]];
  if (list.length < k) return [];
  final result = <List<T>>[];
  for (var i = 0; i <= list.length - k; i++) {
    final head = list[i];
    for (var tail in combinations(list.sublist(i + 1), k - 1)) {
      result.add([head, ...tail]);
    }
  }
  return result;
}

/// Gera as múltiplas (2 a 6 pernas) priorizando Over/Under e marcando time favorito
Future<List<MultiplaSuggestion>> gerarCombinacoesInteligente(
    List<FixturePrediction> jogos, {
      double dcThreshold = DC_THRESHOLD,
      double ouThreshold = OU_THRESHOLD,
      int maxLegs = MAX_LEGS,
      int maxSugestoes = MAX_SUGESTOES,
      double oddMinima = 1.5,
    }) async {
  final agora = DateTime.now();

  // 1) Montar listas de pernas por ordem de prioridade
  final over25 = <EntradaMultipla>[];
  final under25 = <EntradaMultipla>[];
  final over15 = <EntradaMultipla>[];
  final bothGoals = <EntradaMultipla>[];
  final duplaChance = <EntradaMultipla>[];

  for (final m in jogos) {
    if (m.date.isBefore(agora)) continue;
    final link = gerarLink(m);

    // Over 2.5
    if ((m.over25Pct ?? 0) >= ouThreshold) {
      over25.add(EntradaMultipla(
        "${m.home} x ${m.away}",
        "Mais de 2.5 Gols",
        m.over25Pct!,
        link,
      ));
    }

    // Under 2.5
    if ((m.under25Pct ?? 0) >= ouThreshold) {
      under25.add(EntradaMultipla(
        "${m.home} x ${m.away}",
        "Menos de 2.5 Gols",
        m.under25Pct!,
        link,
      ));
    }

    // Over 1.5
    if (m.over15 >= ouThreshold) {
      over15.add(EntradaMultipla(
        "${m.home} x ${m.away}",
        "Mais de 1.5 Gols",
        m.over15,
        link,
      ));
    }

    // Ambas Marcam
    if ((m.ambosMarcamPct ?? 0) >= dcThreshold) {
      bothGoals.add(EntradaMultipla(
        "${m.home} x ${m.away}",
        "Ambas Marcam",
        m.ambosMarcamPct!,
        link,
      ));
    }

    // Dupla Chance: identificar time ou empate
    if (m.doubleChancePct >= dcThreshold) {
      final lc = m.doubleChance.toLowerCase();
      String fav = "Vitória ou Empate";
      if (lc.contains(m.home.toLowerCase())) {
        fav = "${m.home} ou Empate";
      } else if (lc.contains(m.away.toLowerCase())) {
        fav = "${m.away} ou Empate";
      }
      duplaChance.add(EntradaMultipla(
        "${m.home} x ${m.away}",
        "Dupla Chance: $fav",
        m.doubleChancePct,
        link,
      ));
    }
  }

  // 2) Agrupar todas as pernas na ordem de prioridade
  var legs = <EntradaMultipla>[]
    ..addAll(over25)
    ..addAll(under25)
    ..addAll(over15)
    ..addAll(bothGoals)
    ..addAll(duplaChance);

  //  Limitar quantidade de pernas para performance
  if (legs.length > maxLegs) {
    legs = legs.sublist(0, maxLegs);
  }

  // 3) Gerar combos de 2 a 6 pernas
  final sugeridas = <MultiplaSuggestion>[];
  for (final k in [2, 3, 4, 5, 6]) {
    for (final combo in combinations(legs, k)) {
      final partidas = combo.map((e) => e.partida).toSet();
      if (partidas.length < k) continue;

      final oddTotal = combo.map((e) => probToOdd(e.prob)).fold(1.0, (a, b) => a * b);
      final probTotal = combo.map((e) => e.prob / 100).fold(1.0, (a, b) => a * b) * 100;

      if (oddTotal >= oddMinima) {
        sugeridas.add(MultiplaSuggestion(legs: combo, odd: oddTotal, prob: probTotal));
      }
    }
  }

  // 4) Ordenar e remover duplicatas por perna
  sugeridas.sort((a, b) => b.prob.compareTo(a.prob));
  final finalizadas = <MultiplaSuggestion>[];
  final usados = <String>{};

  for (final s in sugeridas) {
    final chaves = s.legs.map((e) => "${e.partida}|${e.tipo}");
    if (chaves.any((k) => usados.contains(k))) continue;
    finalizadas.add(s);
    usados.addAll(chaves);
    if (finalizadas.length >= maxSugestoes) break;
  }

  return finalizadas;
}
