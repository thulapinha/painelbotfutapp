import 'package:flutter/material.dart';
import '../../models/fixture_prediction.dart';
import '../../services/football_api_service.dart';
import '../../services/telegram_service.dart';

class LiveMatch {
  final int id;
  final String home;
  final String away;
  final String time;
  final double over15;
  final double xgSum;

  LiveMatch({
    required this.id,
    required this.home,
    required this.away,
    required this.time,
    required this.over15,
    required this.xgSum,
  });
}

class LivePage extends StatefulWidget {
  final Future<List<FixturePrediction>> future;
  const LivePage({required this.future, Key? key}) : super(key: key);

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late final Future<List<LiveMatch>> _futureMatches;

  @override
  void initState() {
    super.initState();
    _futureMatches = _fetchLiveMatches();
  }

  Future<List<LiveMatch>> _fetchLiveMatches() async {
    // 1) IDs dos jogos previstos
    final preList = await widget.future;
    final preIds = preList.map((e) => e.id).toSet();

    // 2) Chama a API de jogos de hoje
    dynamic raw;
    try {
      raw = await FootballApiService.getTodayFixtures();
    } catch (_) {
      return [];
    }

    // 3) Extrai a lista de fixtures, seja raw List ou raw['response']
    List<dynamic> fixtures;
    if (raw is List) {
      fixtures = raw;
    } else if (raw is Map<String, dynamic> && raw['response'] is List) {
      fixtures = raw['response'];
    } else {
      return [];
    }

    const liveStatuses = ['1H', '2H', 'LIVE', 'HT'];
    const int maxCalls = 5;
    int calls = 0;
    final List<LiveMatch> result = [];

    for (final item in fixtures) {
      if (calls >= maxCalls) break;
      if (item is! Map<String, dynamic>) continue;

      // a) Converte o ID para int de forma segura
      final fx = item['fixture'];
      if (fx is! Map<String, dynamic>) continue;
      final rawId = fx['id'];
      final int? id = rawId is int
          ? rawId
          : (rawId is String ? int.tryParse(rawId) : null);
      if (id == null || !preIds.contains(id)) continue;

      // b) Verifica status ao vivo
      final status = fx['status'];
      if (status is! Map<String, dynamic>) continue;
      final short = status['short']?.toString() ?? '';
      if (!liveStatuses.contains(short)) continue;

      // c) Faz a previsão de gols
      calls++;
      final pred = await FootballApiService.getPrediction(id);
      if (pred == null) continue;
      final preds = pred['predictions'];
      if (preds is! Map<String, dynamic>) continue;

      // Over1.5 (%)
      final rawOver = preds['under_over']
      ?['goals']?['over_1_5']?['percentage'];
      double over15 = 0;
      if (rawOver is num) {
        over15 = rawOver.toDouble();
      } else if (rawOver is String) {
        over15 = double.tryParse(rawOver.replaceAll('%', '')) ?? 0;
      }

      // xG home + away
      final rawH = preds['xGoals']?['home']?['total'];
      final rawA = preds['xGoals']?['away']?['total'];
      double xgH = rawH is num
          ? rawH.toDouble()
          : (rawH is String ? double.tryParse(rawH) ?? 0 : 0);
      double xgA = rawA is num
          ? rawA.toDouble()
          : (rawA is String ? double.tryParse(rawA) ?? 0 : 0);

      // d) Filtra potencial de gol
      if (over15 < 60 && (xgH + xgA) < 1.0) continue;

      // e) Extrai times e tempo decorrido
      final teams = item['teams'];
      if (teams is! Map<String, dynamic>) continue;
      final homeName = teams['home']?['name']?.toString() ?? '';
      final awayName = teams['away']?['name']?.toString() ?? '';
      final elapsed = status['elapsed']?.toString() ?? '--';

      result.add(LiveMatch(
        id: id,
        home: homeName,
        away: awayName,
        time: elapsed,
        over15: over15,
        xgSum: xgH + xgA,
      ));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LiveMatch>>(
      future: _futureMatches,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final games = snap.data!;
        if (games.isEmpty) {
          return const Center(child: Text('Nenhum jogo ao vivo com potencial.'));
        }

        return ListView.builder(
          itemCount: games.length,
          itemBuilder: (ctx, i) {
            final m = games[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("⚽ ${m.home} x ${m.away}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("⏱️ ${m.time} min"),
                    Text("📊 Over 1.5 Gols: ${m.over15.toStringAsFixed(0)}%"),
                    Text("⚽ xG combinado: ${m.xgSum.toStringAsFixed(2)}"),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text("Alerta de Gol"),
                      onPressed: () {
                        final msg = """
🔥 *BotFut – Alerta de Gol* 🔥

⚽ ${m.home} x ${m.away}
⏱️ ${m.time} min

📊 Probabilidade de +1.5 Gols: ${m.over15.toStringAsFixed(0)}%
⚽ xG combinado: ${m.xgSum.toStringAsFixed(2)}

🔎 Potencial de gol detectado!
""";
                        TelegramService.sendMarkdownMessage(msg,
                            disablePreview: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Alerta enviado!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
