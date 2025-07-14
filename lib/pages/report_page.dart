import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction.dart';
import '../services/football_api_service.dart';
import '../services/telegram_service.dart';

class ReportPage extends StatefulWidget {
  final Future<List<FixturePrediction>> future;
  const ReportPage({required this.future, Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<void> _initFuture;
  List<FixturePrediction> _preLive = [];
  List<Map<String, String>> _finished = [];
  List<FixturePrediction> _pending = [];

  @override
  void initState() {
    super.initState();
    _initFuture = _prepararRelatorio(widget.future);
  }

  Future<void> _prepararRelatorio(Future<List<FixturePrediction>> future) async {
    final preLive = await future;
    final fixtures = await FootballApiService.getTodayFixtures();

    final List<Map<String, String>> finalizados = [];
    final List<FixturePrediction> pendentes = [];

    const encerrados = ['FT', 'AET', 'PEN'];

    for (final tip in preLive) {
      final fx = fixtures.firstWhere((f) => f['fixture']['id'] == tip.id, orElse: () => null);
      if (fx == null) continue;

      final status = fx['fixture']['status']['short']?.toString() ?? '';
      if (!encerrados.contains(status)) {
        pendentes.add(tip);
        continue;
      }

      final home = fx['teams']['home']['name'] as String;
      final away = fx['teams']['away']['name'] as String;
      final goals = fx['goals'] as Map<String, dynamic>? ?? {};
      final hG = (goals['home'] ?? 0) as int;
      final aG = (goals['away'] ?? 0) as int;
      final totalGols = hG + aG;

      final principal = _getMelhorEntrada(tip);
      final extra = tip.secondaryAdvice ?? '';

      // Validação principal
      String res1 = '❌ RED';
      String motivo1 = '';
      if (principal.label == 'Casa vence') {
        res1 = hG > aG ? '✅ GREEN' : '❌ RED';
        motivo1 = hG > aG ? 'Mandante venceu ($hG x $aG)' : 'Mandante não venceu ($hG x $aG)';
      } else {
        res1 = aG > hG ? '✅ GREEN' : '❌ RED';
        motivo1 = aG > hG ? 'Visitante venceu ($hG x $aG)' : 'Visitante não venceu ($hG x $aG)';
      }

      // Validação complementar
      String res2 = '❌ RED';
      String motivo2 = '';
      if (extra.contains('Empate')) {
        final ok = hG == aG ||
            (extra.contains(home) && hG >= aG) ||
            (extra.contains(away) && aG >= hG);
        res2 = ok ? '✅ GREEN' : '❌ RED';
        motivo2 = 'Dupla chance: $extra ($hG x $aG)';
      } else if (extra.contains('Over')) {
        final over = double.tryParse(extra.replaceAll(RegExp(r'[^\d\.]'), '')) ?? 2.5;
        res2 = totalGols > over ? '✅ GREEN' : '❌ RED';
        motivo2 = 'Total de gols: $totalGols > $over';
      } else if (extra.contains('Under')) {
        final under = double.tryParse(extra.replaceAll(RegExp(r'[^\d\.]'), '')) ?? 2.5;
        res2 = totalGols < under ? '✅ GREEN' : '❌ RED';
        motivo2 = 'Total de gols: $totalGols < $under';
      } else {
        res2 = '⏳';
        motivo2 = 'Sem validação para \"$extra\"';
      }

      finalizados.add({
        'match': '$home $hG x $aG $away',
        'category': principal.label,
        'extra': extra,
        'result': res1,
        'result_extra': res2,
        'reason': motivo1,
        'reason_extra': motivo2,
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    await prefs.setString('report_$today', jsonEncode(finalizados));

    setState(() {
      _preLive = preLive;
      _finished = finalizados;
      _pending = preLive.where((m) => pendentes.contains(m)).toList();
    });
  }

  _EntradaSugestao _getMelhorEntrada(FixturePrediction m) {
    final op = {'Casa vence': m.homePct, 'Fora vence': m.awayPct};
    final best = op.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return _EntradaSugestao(best.key, best.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📝 Confirmar Resultados')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_pending.isNotEmpty) ...[
                  const Text('⏳ Aguardando confirmação',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._pending.map((m) {
                    final lbl = _getMelhorEntrada(m).label;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text("${m.home} x ${m.away}"),
                        subtitle: Text("📌 $lbl\n📌 ${m.secondaryAdvice ?? '–'}"),
                      ),
                    );
                  }),
                  const Divider(height: 24),
                ],
                const Text('✅ Jogos finalizados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._finished.map((r) {
                  final isGreen = r['result'] == '✅ GREEN';
                  final isGreen2 = r['result_extra'] == '✅ GREEN';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text("📋 ${r['category']} + ${r['extra']}"),
                      subtitle: Text("${r['match']}\n📝 ${r['reason']}\n📝 ${r['reason_extra']}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(r['result']!,
                              style: TextStyle(fontWeight: FontWeight.bold, color: isGreen ? Colors.green : Colors.red)),
                          Text(r['result_extra']!,
                              style: TextStyle(fontWeight: FontWeight.bold, color: isGreen2 ? Colors.green : Colors.red)),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        final msg = """
📊 *BotFut – Relatório*
🏟️ ${r['match']}
📌 Dica principal: ${r['category']} – ${r['result']}
📝 ${r['reason']}
📌 Dica complementar: ${r['extra']} – ${r['result_extra']}
📝 ${r['reason_extra']}
""";
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("📋 Detalhes do Jogo"),
                            content: Text(msg),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Fechar"),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.send),
                                label: const Text("Enviar Telegram"),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await TelegramService.sendMessage(msg);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Relatório enviado ao Telegram!")),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EntradaSugestao {
  final String label;
  final double pct;
  _EntradaSugestao(this.label, this.pct);
}
