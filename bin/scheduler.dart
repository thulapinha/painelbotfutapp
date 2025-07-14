import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─── CONSTS DO TELEGRAM E API-SPORTS ─────────────────────────────────────────
const String _botToken = '7854661345:AAEzg74OEidhdWB7_uJ9hefKdoBlGCV94f4';
const String _chatId = '709273579';
const String _apiKey = 'ffebc5794b0d9f51fd639ac54563b848';

const String _baseUrl = 'https://v3.football.api-sports.io';
const String _fixturesPath = '/fixtures';
const String _predsPath = '/predictions';

String get _telegramUrl => 'https://api.telegram.org/bot$_botToken/sendMessage';

// ─── MAIN ────────────────────────────────────────────────────────────────────
Future<void> main() async {
  final now = DateTime.now();
  final today = now.toIso8601String().split('T').first;

  // 1) busca as fixtures do dia
  final fxResp = await http.get(
    Uri.parse('$_baseUrl$_fixturesPath?date=$today&timezone=America/Sao_Paulo'),
    headers: {'x-apisports-key': _apiKey},
  );
  if (fxResp.statusCode != 200) {
    stderr.writeln(
      'Erro ao buscar fixtures (${fxResp.statusCode}): ${fxResp.body}',
    );
    return;
  }

  final List fxList = (jsonDecode(fxResp.body)['response'] as List);
  final fixtures = fxList.map((j) => Fixture.fromJson(j)).toList();
  if (fixtures.isEmpty) {
    print('Não há jogos hoje. Encerrando.');
    return;
  }

  final sentTips = <int>{};
  final sentResults = <int>{};

  // 2) agenda envio de tip 30 minutos antes de cada jogo
  for (final f in fixtures) {
    final sendAt = f.date.subtract(const Duration(minutes: 30));
    final diff = sendAt.difference(now);
    if (diff.isNegative) continue;

    Timer(diff, () async {
      if (sentTips.contains(f.id)) return;

      final prRes = await http.get(
        Uri.parse('$_baseUrl$_predsPath?fixture=${f.id}'),
        headers: {'x-apisports-key': _apiKey},
      );
      if (prRes.statusCode != 200) {
        stderr.writeln(
          'Erro ao buscar previsão (${f.id}): ${prRes.statusCode}',
        );
        return;
      }

      final List prList = (jsonDecode(prRes.body)['response'] as List);
      if (prList.isEmpty) return;

      final predJson =
          prList.first['predictions'] as Map<String, dynamic>? ?? {};
      final pred = Prediction.fromJson(predJson, f);
      final best = _getMelhorEntrada(pred);

      final msg =
          """
🎯 *BotFut – Tip*
⚽ ${f.home} x ${f.away}
📅 ${_two(f.date.day)}/${_two(f.date.month)} ⏰ ${_two(f.date.hour)}:${_two(f.date.minute)}
📌 Estratégia: ${best.label}
""";
      await _sendTelegram(msg);
      sentTips.add(f.id);
      print('Tip enviada para jogo ${f.id} em ${DateTime.now()}');
    });
  }

  // 3) polling de resultados a cada 10 minutos
  final ticker = Timer.periodic(const Duration(minutes: 10), (timer) async {
    final now2 = DateTime.now();
    final fxRes = await http.get(
      Uri.parse(
        '$_baseUrl$_fixturesPath?date=$today&timezone=America/Sao_Paulo',
      ),
      headers: {'x-apisports-key': _apiKey},
    );
    if (fxRes.statusCode != 200) {
      stderr.writeln('Erro polling fixtures (${fxRes.statusCode})');
      return;
    }

    final List fxList2 = (jsonDecode(fxRes.body)['response'] as List);
    for (final f in fixtures) {
      if (sentResults.contains(f.id) || f.date.isAfter(now2)) continue;

      final match = fxList2.firstWhere(
        (m) => (m['fixture']?['id'] as int? ?? -1) == f.id,
        orElse: () => null,
      );
      if (match == null) continue;

      final status = match['fixture']?['status']?['short'] as String? ?? '';
      if (!['FT', 'AET', 'PEN'].contains(status)) continue;

      final hg = (match['goals']?['home'] ?? 0) as int;
      final ag = (match['goals']?['away'] ?? 0) as int;
      final total = hg + ag;

      // rebusca previsão para checar resultado
      final prRes2 = await http.get(
        Uri.parse('$_baseUrl$_predsPath?fixture=${f.id}'),
        headers: {'x-apisports-key': _apiKey},
      );
      if (prRes2.statusCode != 200) continue;
      final List prList2 = (jsonDecode(prRes2.body)['response'] as List);
      if (prList2.isEmpty) continue;

      final predJson2 =
          prList2.first['predictions'] as Map<String, dynamic>? ?? {};
      final pred2 = Prediction.fromJson(predJson2, f);
      final best2 = _getMelhorEntrada(pred2);
      final label = best2.label;

      String result = '⏳', reason = '';
      if (label.contains('Casa vence')) {
        final ok = hg > ag;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Mandante ${ok ? 'venceu' : 'não venceu'} ($hg x $ag)';
      } else if (label.contains('Fora vence')) {
        final ok = ag > hg;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Visitante ${ok ? 'venceu' : 'não venceu'} ($hg x $ag)';
      } else if (label.contains('Over 2.5')) {
        final ok = total > 2.5;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Total gols: $total';
      } else if (label.contains('Over 1.5')) {
        final ok = total > 1.5;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Total gols: $total';
      } else if (label.contains('Under 2.5')) {
        final ok = total < 2.5;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Total gols: $total';
      } else if (label.contains('Ambas Marcam')) {
        final ok = hg > 0 && ag > 0;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Placar: $hg x $ag';
      } else if (label.contains('Dupla Chance')) {
        final txt = label.toLowerCase();
        final ok =
            (txt.contains(f.home.toLowerCase()) && hg >= ag) ||
            (txt.contains(f.away.toLowerCase()) && ag >= hg) ||
            hg == ag;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Final: $hg x $ag';
      }

      final msg =
          """
📊 *BotFut – Resultado*
⚽ ${f.home} $hg x $ag ${f.away}
📌 Estratégia: $label
🎯 Resultado: $result
📝 Motivo: $reason
""";
      await _sendTelegram(msg);
      sentResults.add(f.id);
      print('Resultado enviado para jogo ${f.id} em ${DateTime.now()}');
    }

    if (sentResults.length == fixtures.length) {
      timer.cancel();
      print('Todos resultados enviados. Scheduler encerrado.');
    }
  });
}

// ─── FUNÇÕES AUXILIARES ─────────────────────────────────────────────────────
Future<void> _sendTelegram(String text) async {
  final resp = await http.post(
    Uri.parse(_telegramUrl),
    body: {'chat_id': _chatId, 'text': text, 'parse_mode': 'Markdown'},
  );
  if (resp.statusCode != 200) {
    stderr.writeln(
      'Erro ao enviar Telegram (${resp.statusCode}): ${resp.body}',
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

// ─── MODELOS ────────────────────────────────────────────────────────────────
class Fixture {
  final int id;
  final String home, away;
  final DateTime date;
  final double homePct, awayPct;

  Fixture({
    required this.id,
    required this.home,
    required this.away,
    required this.date,
    required this.homePct,
    required this.awayPct,
  });

  factory Fixture.fromJson(Map j) {
    final fx = j['fixture'] as Map<String, dynamic>? ?? {};
    final teams = fx['teams'] as Map<String, dynamic>? ?? {};
    final dateStr = fx['date'] as String? ?? '';
    final date = dateStr.isNotEmpty
        ? DateTime.parse(dateStr).toLocal()
        : DateTime.now();

    final preds = (j['predictions'] as List?) ?? [];
    final rawPred = preds.isNotEmpty ? preds.first['predictions'] : null;
    final predMap = rawPred is Map<String, dynamic>
        ? rawPred
        : <String, dynamic>{};
    final perMap = predMap['percent'] as Map<String, dynamic>? ?? {};

    double _p(dynamic v) {
      if (v == null) return 0;
      return double.tryParse(v.toString().replaceAll('%', '').trim()) ?? 0;
    }

    return Fixture(
      id: fx['id'] as int? ?? 0,
      home: teams['home']?['name'] as String? ?? '',
      away: teams['away']?['name'] as String? ?? '',
      date: date,
      homePct: _p(perMap['home']),
      awayPct: _p(perMap['away']),
    );
  }
}

class Prediction {
  final int id;
  final double homePct, awayPct;
  final String? doubleChance;
  final double doubleChancePct;
  final double over15;
  final String? over25Label;
  final double? over25Pct;
  final String? under25Label;
  final double? under25Pct;
  final String? ambosMarcamLabel;
  final double? ambosMarcamPct;

  Prediction({
    required this.id,
    required this.homePct,
    required this.awayPct,
    this.doubleChance,
    required this.doubleChancePct,
    required this.over15,
    this.over25Label,
    this.over25Pct,
    this.under25Label,
    this.under25Pct,
    this.ambosMarcamLabel,
    this.ambosMarcamPct,
  });

  factory Prediction.fromJson(Map<String, dynamic> p, Fixture f) {
    double _p(dynamic v) {
      if (v == null) return 0;
      return double.tryParse(v.toString().replaceAll('%', '').trim()) ?? 0;
    }

    final pctMap = p['percent'] as Map<String, dynamic>? ?? {};
    final hp = _p(pctMap['home']);
    final ap = _p(pctMap['away']);

    final dcLabel = p['doubleChance']?['label'] as String?;
    final dcPct = _p(p['doubleChance']?['percentage']);

    final o15 = _p(p['under_over']?['goals']?['over_1_5']?['percentage']);
    final o25Lab = p['under_over']?['goals']?['over_2_5']?['label'] as String?;
    final o25Pct = _p(p['under_over']?['goals']?['over_2_5']?['percentage']);
    final u25Lab = p['under_over']?['goals']?['under_2_5']?['label'] as String?;
    final u25Pct = _p(p['under_over']?['goals']?['under_2_5']?['percentage']);
    final bmLab = p['goals']?['both']?['teams']?['label'] as String?;
    final bmPct = _p(p['goals']?['both']?['teams']?['percentage']);

    return Prediction(
      id: f.id,
      homePct: hp,
      awayPct: ap,
      doubleChance: dcLabel,
      doubleChancePct: dcPct,
      over15: o15,
      over25Label: o25Lab,
      over25Pct: o25Pct == 0 ? null : o25Pct,
      under25Label: u25Lab,
      under25Pct: u25Pct == 0 ? null : u25Pct,
      ambosMarcamLabel: bmLab,
      ambosMarcamPct: bmPct == 0 ? null : bmPct,
    );
  }
}

class _EntradaSugestao {
  final String label;
  final double pct;
  _EntradaSugestao(this.label, this.pct);
}

_EntradaSugestao _getMelhorEntrada(Prediction m) {
  final opts = <_EntradaSugestao>[];

  if ((m.doubleChance ?? '').isNotEmpty && m.doubleChancePct > 70) {
    opts.add(
      _EntradaSugestao("Dupla Chance: ${m.doubleChance}", m.doubleChancePct),
    );
  }
  if ((m.over25Label ?? '').isNotEmpty && (m.over25Pct ?? 0) > 70) {
    opts.add(_EntradaSugestao("Over 2.5", m.over25Pct!));
  }
  if ((m.under25Label ?? '').isNotEmpty && (m.under25Pct ?? 0) > 70) {
    opts.add(_EntradaSugestao("Under 2.5", m.under25Pct!));
  }
  if (m.over15 > 70) {
    opts.add(_EntradaSugestao("Over 1.5", m.over15));
  }
  if ((m.ambosMarcamLabel ?? '').isNotEmpty && (m.ambosMarcamPct ?? 0) > 70) {
    opts.add(_EntradaSugestao("Ambas Marcam", m.ambosMarcamPct!));
  }
  if (m.homePct > 70) {
    opts.add(_EntradaSugestao("Casa vence", m.homePct));
  }
  if (m.awayPct > 70) {
    opts.add(_EntradaSugestao("Fora vence", m.awayPct));
  }

  if (opts.isEmpty) {
    final fallback = <_EntradaSugestao>[
      if ((m.doubleChance ?? '').isNotEmpty)
        _EntradaSugestao("Dupla Chance: ${m.doubleChance}", m.doubleChancePct),
      if (m.over25Pct != null) _EntradaSugestao("Over 2.5", m.over25Pct!),
      if (m.under25Pct != null) _EntradaSugestao("Under 2.5", m.under25Pct!),
      if (m.over15 > 0) _EntradaSugestao("Over 1.5", m.over15),
      if (m.ambosMarcamPct != null)
        _EntradaSugestao("Ambas Marcam", m.ambosMarcamPct!),
      _EntradaSugestao("Casa vence", m.homePct),
      _EntradaSugestao("Fora vence", m.awayPct),
    ];
    fallback.sort((a, b) => b.pct.compareTo(a.pct));
    return fallback.first;
  }

  opts.sort((a, b) => b.pct.compareTo(a.pct));
  return opts.first;
}
