import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─── DADOS DA API E DO BOT TELEGRAM ─────────────────────────────────────────
const String _botToken = '7854661345:AAEzg74OEidhdWB7_uJ9hefKdoBlGCV94f4';
const String _chatId   = '709273579';
const String _apiKey   = 'ffebc5794b0d9f51fd639ac54563b848';

const Map<String, String> _headers = {
  'x-apisports-key': _apiKey,
};

const String _baseUrl      = 'https://v3.football.api-sports.io';
const String _fixturesPath = '/fixtures';
const String _predsPath    = '/predictions';

String get _telegramUrl =>
    'https://api.telegram.org/bot$_botToken/sendMessage';
// ────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  final now   = DateTime.now();
  final today = now.toIso8601String().split('T').first;

  // 1) Busca fixtures de hoje para agendar tips
  final fixturesUrl = Uri.parse(
      '$_baseUrl$_fixturesPath?date=$today&timezone=America/Sao_Paulo'
  );
  final fxResp = await http.get(fixturesUrl, headers: _headers);
  if (fxResp.statusCode != 200) {
    stderr.writeln('Erro ao buscar fixtures (${fxResp.statusCode}): ${fxResp.body}');
    exit(1);
  }

  final List fxList = (jsonDecode(fxResp.body)['response'] as List);
  final fixtures = fxList.map((j) => Fixture.fromJson(j)).toList();

  if (fixtures.isEmpty) {
    print('Não há jogos hoje. Encerrando scheduler.');
    return;
  }

  final sentTips = <int>{};
  final sentRes  = <int>{};

  // 2) Agenda envio de tip 30 minutos antes de cada jogo
  for (final m in fixtures) {
    final sendAt = m.date.subtract(const Duration(minutes: 30));
    final diff   = sendAt.difference(now);
    if (diff.isNegative) continue;

    Timer(diff, () async {
      if (sentTips.contains(m.id)) return;

      // Busca a previsão exata para esta partida
      final prUrl = Uri.parse('$_baseUrl$_predsPath?fixture=${m.id}');
      final prResp = await http.get(prUrl, headers: _headers);
      if (prResp.statusCode != 200) {
        stderr.writeln('Erro ao buscar previsão ${m.id}: ${prResp.statusCode}');
        return;
      }

      final List prList = (jsonDecode(prResp.body)['response'] as List);
      if (prList.isEmpty) return; // sem previsão

      final predJson = prList.first['predictions'] as Map<String, dynamic>;
      final mPred = Prediction.fromJson(predJson, m);

      final best = _getMelhorEntrada(mPred);
      final msg = """
🎯 *BotFut – Tip*
⚽ ${m.home} x ${m.away}
📅 ${m.date.day}/${m.date.month} ⏰ ${_two(m.date.hour)}:${_two(m.date.minute)}
📌 Estratégia: ${best.label}
""";
      await _sendTelegram(msg);
      sentTips.add(m.id);
      stdout.writeln('Tip enviada para jogo ${m.id} em ${DateTime.now()}');
    });
  }

  // 3) Polling a cada 5min para reportar resultados
  final ticker = Timer.periodic(const Duration(minutes: 5), (timer) async {
    final fxUrl  = Uri.parse(
        '$_baseUrl$_fixturesPath?date=$today&timezone=America/Sao_Paulo'
    );
    final fxResp = await http.get(fxUrl, headers: _headers);
    if (fxResp.statusCode != 200) {
      stderr.writeln('Erro ao buscar fixtures (${fxResp.statusCode})');
      return;
    }

    final List newFx = (jsonDecode(fxResp.body)['response'] as List);
    for (final m in fixtures) {
      if (sentRes.contains(m.id) || m.date.isAfter(DateTime.now())) continue;

      final fxMatch = newFx.firstWhere(
            (f) => (f['fixture']['id'] as int) == m.id,
        orElse: () => null,
      );
      if (fxMatch == null) continue;

      final status = fxMatch['fixture']['status']['short'] as String? ?? '';
      if (!['FT', 'AET', 'PEN'].contains(status)) continue;

      final hg    = (fxMatch['goals']['home'] ?? 0) as int;
      final ag    = (fxMatch['goals']['away'] ?? 0) as int;

      // Rebusca a previsão para avaliar o resultado
      final prUrl2 = Uri.parse('$_baseUrl$_predsPath?fixture=${m.id}');
      final prResp2 = await http.get(prUrl2, headers: _headers);
      if (prResp2.statusCode != 200) continue;
      final List prList2 = (jsonDecode(prResp2.body)['response'] as List);
      if (prList2.isEmpty) continue;
      final predJson2 = prList2.first['predictions'] as Map<String, dynamic>;
      final mPred2 = Prediction.fromJson(predJson2, m);

      final best2 = _getMelhorEntrada(mPred2);
      final label = best2.label;

      String result = '⏳', reason = '';
      final total = hg + ag;

      if (label.contains('Casa vence')) {
        result = hg > ag ? '✅ GREEN' : '❌ RED';
        reason = 'Mandante venceu ($hg x $ag)';
      } else if (label.contains('Fora vence')) {
        result = ag > hg ? '✅ GREEN' : '❌ RED';
        reason = 'Visitante venceu ($hg x $ag)';
      } else if (label.contains('Over 2.5')) {
        result = total > 2.5 ? '✅ GREEN' : '❌ RED';
        reason = 'Gols: $total';
      } else if (label.contains('Over 1.5')) {
        result = total > 1.5 ? '✅ GREEN' : '❌ RED';
        reason = 'Gols: $total';
      } else if (label.contains('Under 2.5')) {
        result = total < 2.5 ? '✅ GREEN' : '❌ RED';
        reason = 'Gols: $total';
      } else if (label.contains('Ambas Marcam')) {
        final ok = hg > 0 && ag > 0;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Placar: $hg x $ag';
      } else if (label.contains('Dupla Chance')) {
        final txt = label.toLowerCase();
        final ok = (txt.contains(m.home.toLowerCase()) && hg >= ag) ||
            (txt.contains(m.away.toLowerCase()) && ag >= hg) ||
            hg == ag;
        result = ok ? '✅ GREEN' : '❌ RED';
        reason = 'Final: $hg x $ag';
      }

      final msg = """
📊 *BotFut – Resultado*
⚽ ${m.home} $hg x $ag ${m.away}
📌 Estratégia: $label
🎯 Resultado: $result
📝 Motivo: $reason
""";
      await _sendTelegram(msg);
      sentRes.add(m.id);
      stdout.writeln('Resultado enviado para jogo ${m.id} em ${DateTime.now()}');
    }

    if (sentRes.length == fixtures.length) {
      timer.cancel();
    }
  });

  // 4) Mantém o script vivo até 1h após o último jogo
  final last = fixtures.map((m) => m.date).reduce((a, b) => a.isAfter(b) ? a : b);
  final wait = last.difference(now) + const Duration(hours: 1);
  await Future.delayed(wait);
  if (ticker.isActive) ticker.cancel();
  stdout.writeln('Scheduler finalizado em ${DateTime.now()}');
}

Future<void> _sendTelegram(String text) async {
  final resp = await http.post(
    Uri.parse(_telegramUrl),
    body: {
      'chat_id'   : _chatId,
      'text'      : text,
      'parse_mode': 'Markdown',
    },
  );
  if (resp.statusCode != 200) {
    stderr.writeln('Erro ao enviar Telegram (${resp.statusCode}): ${resp.body}');
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Modelo de Fixture do scheduler
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
    final fx = j['fixture'] as Map<String, dynamic>;
    final teams = fx['teams'] as Map<String, dynamic>;
    final date = DateTime.parse(fx['date'] as String).toLocal();

    final preds = (j['predictions'] as List?) ?? [];
    final firstPred = preds.isNotEmpty ? preds.first['predictions'] as Map<String, dynamic> : {};
    final percent = firstPred['percent'] as Map<String, dynamic>? ?? {};
    double _p(dynamic v) {
      if (v == null) return 0;
      return double.tryParse(v.toString().replaceAll('%','').trim()) ?? 0;
    }

    return Fixture(
      id      : fx['id'] as int,
      home    : teams['home']['name'] as String,
      away    : teams['away']['name'] as String,
      date    : date,
      homePct : _p(percent['home']),
      awayPct : _p(percent['away']),
    );
  }
}

/// Prediction enriquecido para scheduler
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
      return double.tryParse(v.toString().replaceAll('%','').trim()) ?? 0;
    }

    final percent = p['percent'] as Map<String, dynamic>? ?? {};
    final homePct = _p(percent['home']);
    final awayPct = _p(percent['away']);

    final dcLabel = p['doubleChance']?['label'] as String?;
    final dcPct   = _p(p['doubleChance']?['percentage']);

    final over15 = _p(p['under_over']?['goals']?['over_1_5']?['percentage']);

    final o25Label = p['under_over']?['goals']?['over_2_5']?['label'] as String?;
    final o25Pct   = _p(p['under_over']?['goals']?['over_2_5']?['percentage']);

    final u25Label = p['under_over']?['goals']?['under_2_5']?['label'] as String?;
    final u25Pct   = _p(p['under_over']?['goals']?['under_2_5']?['percentage']);

    final bmLabel = p['goals']?['both']?['teams']?['label'] as String?;
    final bmPct   = _p(p['goals']?['both']?['teams']?['percentage']);

    return Prediction(
      id               : f.id,
      homePct          : homePct,
      awayPct          : awayPct,
      doubleChance     : dcLabel,
      doubleChancePct  : dcPct,
      over15           : over15,
      over25Label      : o25Label,
      over25Pct        : o25Pct == 0 ? null : o25Pct,
      under25Label     : u25Label,
      under25Pct       : u25Pct == 0 ? null : u25Pct,
      ambosMarcamLabel : bmLabel,
      ambosMarcamPct   : bmPct == 0 ? null : bmPct,
    );
  }
}

/// Representa uma sugestão de entrada
class _EntradaSugestao {
  final String label;
  final double pct;
  _EntradaSugestao(this.label, this.pct);
}

/// Escolhe a melhor estratégia, exatamente como na sua UI
_EntradaSugestao _getMelhorEntrada(Prediction m) {
  final List<_EntradaSugestao> op = [];

  if ((m.doubleChance ?? '').isNotEmpty && m.doubleChancePct > 70) {
    op.add(_EntradaSugestao("Dupla Chance: ${m.doubleChance}", m.doubleChancePct));
  }
  if ((m.over25Label ?? '').isNotEmpty && (m.over25Pct ?? 0) > 70) {
    op.add(_EntradaSugestao("Over 2.5", m.over25Pct!));
  }
  if ((m.under25Label ?? '').isNotEmpty && (m.under25Pct ?? 0) > 70) {
    op.add(_EntradaSugestao("Under 2.5", m.under25Pct!));
  }
  if (m.over15 > 70) {
    op.add(_EntradaSugestao("Over 1.5", m.over15));
  }
  if ((m.ambosMarcamLabel ?? '').isNotEmpty && (m.ambosMarcamPct ?? 0) > 70) {
    op.add(_EntradaSugestao("Ambas Marcam", m.ambosMarcamPct!));
  }
  if (m.homePct > 70) {
    op.add(_EntradaSugestao("Casa vence", m.homePct));
  }
  if (m.awayPct > 70) {
    op.add(_EntradaSugestao("Fora vence", m.awayPct));
  }

  if (op.isEmpty) {
    final fb = <_EntradaSugestao>[
      if ((m.doubleChance ?? '').isNotEmpty)
        _EntradaSugestao("Dupla Chance: ${m.doubleChance}", m.doubleChancePct),
      if (m.over25Pct != null)
        _EntradaSugestao("Over 2.5", m.over25Pct!),
      if (m.under25Pct != null)
        _EntradaSugestao("Under 2.5", m.under25Pct!),
      if (m.over15 > 0)
        _EntradaSugestao("Over 1.5", m.over15),
      if (m.ambosMarcamPct != null)
        _EntradaSugestao("Ambas Marcam", m.ambosMarcamPct!),
      _EntradaSugestao("Casa vence", m.homePct),
      _EntradaSugestao("Fora vence", m.awayPct),
    ];
    fb.sort((a, b) => b.pct.compareTo(a.pct));
    return fb.first;
  }

  op.sort((a, b) => b.pct.compareTo(a.pct));
  return op.first;
}
