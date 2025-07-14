// lib/home.dart
import 'package:flutter/material.dart';
import 'package:botfutapp/models/fixture_prediction.dart';
import 'package:botfutapp/services/pre_live_service.dart';
import 'package:botfutapp/pages/pre_live_page.dart';
import 'package:botfutapp/pages/multipla_page.dart' as mp;
import 'package:botfutapp/pages/live_page.dart';
import 'package:botfutapp/pages/historico_page.dart';
import 'package:botfutapp/pages/stats_page.dart';
import 'package:botfutapp/pages/report_page.dart';

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

        list.sort((a, b) => a.date.compareTo(b.date));
        final proximo = futuros.isNotEmpty ? futuros.first : list.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(
                    Icons.flash_on,
                    size: 36,
                    color: Colors.green,
                  ),
                  title: Text("${proximo.home} x ${proximo.away}"),
                  subtitle: Text("Dica: ${proximo.advice}"),
                  trailing: Text(
                    "${proximo.date.hour.toString().padLeft(2, '0')}:${proximo.date.minute.toString().padLeft(2, '0')}",
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text("Próximos Jogos (${futuros.length})"),
                  children: futuros
                      .take(5)
                      .map(
                        (m) => ListTile(
                          title: Text("${m.home} x ${m.away}"),
                          subtitle: Text(m.advice),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              if (aoVivo.isNotEmpty)
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.play_circle_fill),
                    title: Text("Ao Vivo (${aoVivo.length})"),
                    children: aoVivo
                        .map(
                          (m) => ListTile(
                            title: Text("${m.home} x ${m.away}"),
                            subtitle: Text("⏱️ ${m.elapsedTime ?? '--'} min"),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Atualizar"),
                      onPressed: () {
                        setState(() {
                          _preLiveFuture = PreLiveService.getPreLive(
                            forceRefresh: true,
                          );
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
                          MaterialPageRoute(builder: (_) => const StatsPage()),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Confirmar Resultados"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportPage(future: _preLiveFuture),
                          ),
                        );
                      },
                    ),
                  ],
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
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Pré-Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Múltipla',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle),
            label: 'Ao Vivo',
          ),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
