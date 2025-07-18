// lib/home.dart

import 'package:flutter/material.dart';
import 'package:botfutapp/models/fixture_prediction.dart';
import 'package:botfutapp/services/pre_live_service.dart';
import 'package:botfutapp/pages/pre_live/pre_live_page.dart';
import 'package:botfutapp/pages/multiplas/multipla_page.dart' as mp;
import 'package:botfutapp/pages/liver/live_page.dart';
import 'package:botfutapp/pages/confirmacao/historico_page.dart';
import 'package:botfutapp/pages/grafico/stats_page.dart';
import 'package:botfutapp/pages/confirmacao/report_page.dart';


String traduzirTip(String raw) {
  final r = raw.toLowerCase();
  return r
      .replaceAll("double chance", "Dupla Chance")
      .replaceAll("win or draw", "Vitória ou Empate")
      .replaceAll("draw or", "Empate ou")
      .replaceAll("or draw", "ou Empate")
      .replaceAll("or", "ou")
      .replaceAll("+2.5 goals", "Mais de 2.5 Gols")
      .replaceAll("-2.5 goals", "Menos de 2.5 Gols")
      .replaceAll("goals", "Gols")
      .replaceAll(" and ", " e ");
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<FixturePrediction>> _preLiveFuture;
  late List<Widget> _pages;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _preLiveFuture = PreLiveService.getPreLive();
    _pages = [
      _buildDashboard(),
      PreLivePage(future: _preLiveFuture),
      mp.MultiplaPage(future: _preLiveFuture),
      LivePage(future: _preLiveFuture),
    ];
  }

  Widget _buildDashboard() {
    return FutureBuilder<List<FixturePrediction>>(
      future: _preLiveFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final list = snap.data!;
        final now = DateTime.now();
        final futuros = list.where((m) => m.date.isAfter(now)).toList();
        final aoVivo = list.where((m) {
          final s = m.statusShort ?? '';
          return ['1H', '2H', 'LIVE', 'HT'].contains(s);
        }).toList();

        // Ordena por data e escolhe o próximo
        list.sort((a, b) => a.date.compareTo(b.date));
        final proximo = futuros.isNotEmpty ? futuros.first : list.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Legenda de confiança
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🔎 Legenda de Confiança nas Tips",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.green.shade600, size: 14),
                          const SizedBox(width: 6),
                          const Text("Alta confiança (≥ 80%)"),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.orange.shade600, size: 14),
                          const SizedBox(width: 6),
                          const Text("Confiança moderada (65–79%)"),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.grey, size: 14),
                          const SizedBox(width: 6),
                          const Text("Baixa ou ausente (< 65%)"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Próximo jogo
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: const Icon(Icons.flash_on, size: 36, color: Colors.greenAccent),
                  title: Text("${proximo.home} x ${proximo.away}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Dica: ${traduzirTip(proximo.advice)}"),


                    trailing: Text(
                    "${proximo.date.hour.toString().padLeft(2, '0')}:"
                        "${proximo.date.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                ),
              ),

              // Próximos jogos
              const SizedBox(height: 12),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text("Próximos Jogos (${futuros.length})"),
                  children: futuros
                      .take(5)
                      .map((m) => ListTile(
                    title: Text("${m.home} x ${m.away}"),
                    subtitle: Text(m.advice),
                  ))
                      .toList(),
                ),
              ),

              // Jogos ao vivo
              if (aoVivo.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.play_circle_fill),
                    title: Text("Ao Vivo (${aoVivo.length})"),
                    children: aoVivo
                        .map((m) => ListTile(
                      title: Text("${m.home} x ${m.away}"),
                      subtitle: Text("⏱️ ${m.elapsedTime ?? '--'} min"),
                    ))
                        .toList(),
                  ),
                ),
              ],

              // Botões de ação
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Atualizar"),
                        onPressed: () {
                          setState(() {
                            _preLiveFuture =
                                PreLiveService.getPreLive(forceRefresh: true);
                            _pages[0] = _buildDashboard();
                            _pages[1] = PreLivePage(future: _preLiveFuture);
                            _pages[2] = mp.MultiplaPage(future: _preLiveFuture);
                            _pages[3] = LivePage(future: _preLiveFuture);
                          });
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text("Histórico"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoricoPage(),
                            ),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.bar_chart),
                        label: const Text("Estatísticas"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StatsPage(),
                            ),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Confirmar Resultados"),
                        onPressed: () {
                          // remover o 'todosJogos' que não existe
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BotFut Dashboard')),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: Theme.of(context).cardColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Pré-Live'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Múltipla'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Ao Vivo'),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
