import 'package:diacritic/diacritic.dart';
import '../../models/fixture_prediction.dart';
import 'multipla_model.dart';

String gerarLink(FixturePrediction m) {
  var termo = '${m.home} ${m.away}';
  termo = removeDiacritics(termo).replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ').trim();
  final encoded = Uri.encodeComponent(termo);
  return 'https://bet365.bet.br/#/AX/K^$encoded/';
}

double probToOdd(double p) {
  final prob = p / 100;
  return prob > 0 ? (1 / prob).clamp(1.01, 10.0) : 1.01;
}

Future<List<MultiplaSuggestion>> gerarCombinacoes(
    List<FixturePrediction> jogos,
    {double threshold = 65.0, int maxSugestoes = 5}
    ) async {
  final agora = DateTime.now();
  final legs = <EntradaMultipla>[];

  for (final m in jogos) {
    if (m.date.isBefore(agora)) continue;
    final link = gerarLink(m);
    final homePct = m.homePct;
    final awayPct = m.awayPct;
    final drawPct = (100 - homePct - awayPct).clamp(0, 100).toDouble();

    legs.add(EntradaMultipla("${m.home} x ${m.away}", "Casa vence", homePct, link));
    legs.add(EntradaMultipla("${m.home} x ${m.away}", "Empate", drawPct, link));
    legs.add(EntradaMultipla("${m.home} x ${m.away}", "Fora vence", awayPct, link));

    if (m.doubleChancePct >= threshold) {
      legs.add(EntradaMultipla("${m.home} x ${m.away}", "Dupla Chance", m.doubleChancePct, link));
    }
    if ((m.over25Pct ?? 0) >= threshold) {
      legs.add(EntradaMultipla("${m.home} x ${m.away}", "Over 2.5", m.over25Pct!, link));
    }
    if ((m.under25Pct ?? 0) >= threshold) {
      legs.add(EntradaMultipla("${m.home} x ${m.away}", "Under 2.5", m.under25Pct!, link));
    }
    if ((m.ambosMarcamPct ?? 0) >= threshold) {
      legs.add(EntradaMultipla("${m.home} x ${m.away}", "Ambas Marcam", m.ambosMarcamPct!, link));
    }
  }

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

  final combos = <MultiplaSuggestion>[];
  for (var k in [2, 3, 4]) {
    for (var legsCombo in combinations(legs, k)) {
      final partidas = legsCombo.map((e) => e.partida).toSet();
      if (partidas.length < k) continue;
      final odds = legsCombo.map((e) => probToOdd(e.prob));
      final oddTotal = odds.fold(1.0, (a, b) => a * b);
      final probTotal = legsCombo.map((e) => e.prob / 100).fold(1.0, (a, b) => a * b) * 100;
      combos.add(MultiplaSuggestion(legs: legsCombo, odd: oddTotal, prob: probTotal));
    }
  }

  combos.sort((a, b) => b.prob.compareTo(a.prob));
  final filtered = <MultiplaSuggestion>[];
  final used = <String>{};

  for (final s in combos) {
    final keys = s.legs.map((e) => "${e.partida}|${e.tipo}");
    if (keys.any((k) => used.contains(k))) continue;
    filtered.add(s);
    used.addAll(keys);
    if (filtered.length >= maxSugestoes) break;
  }

  return filtered;
}
