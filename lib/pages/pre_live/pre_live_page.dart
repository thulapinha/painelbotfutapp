import 'package:flutter/material.dart';
import '../../models/fixture_prediction.dart';
import '../../services/pre_live_service.dart';
import 'pre_live_card.dart';
import 'pre_live_filter_bar.dart';
import '../../utils/estrategia_util.dart';

class PreLivePage extends StatefulWidget {
  final Future<List<FixturePrediction>> future;
  const PreLivePage({required this.future, Key? key}) : super(key: key);

  @override
  State<PreLivePage> createState() => _PreLivePageState();
}

class _PreLivePageState extends State<PreLivePage> {
  late Future<List<FixturePrediction>> _futureJogos;
  bool _mostrarSomenteFuturos = true;
  bool _somenteConfiaveis = true;

  @override
  void initState() {
    super.initState();
    _futureJogos = widget.future;
  }

  void _refreshNow() {
    setState(() {
      _futureJogos = PreLiveService.getPreLive(forceRefresh: true);
    });
  }

  bool ehTipConfiavel(FixturePrediction jogo, {double minimoPct = 70}) {
    final sugestao = getMelhorSugestao(jogo);
    return sugestao.pct >= minimoPct;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FixturePrediction>>(
      future: _futureJogos,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final jogos = snap.data!;
        final agora = DateTime.now();

        List<FixturePrediction> filtrados = _mostrarSomenteFuturos
            ? jogos.where((j) => j.date.isAfter(agora)).toList()
            : jogos;

        if (_somenteConfiaveis) {
          filtrados = filtrados.where(ehTipConfiavel).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Atualizar agora"),
                    onPressed: _refreshNow,
                  ),
                  FilterChip(
                    label: Text(
                      _mostrarSomenteFuturos ? "Somente futuros" : "Todos os jogos",
                    ),
                    selected: _mostrarSomenteFuturos,
                    onSelected: (v) => setState(() => _mostrarSomenteFuturos = v),
                    selectedColor: Colors.green.shade100,
                  ),
                  FilterChip(
                    label: Text(
                      _somenteConfiaveis ? "Confiáveis (≥70%)" : "Todos os níveis",
                    ),
                    selected: _somenteConfiaveis,
                    onSelected: (v) => setState(() => _somenteConfiaveis = v),
                    selectedColor: Colors.green.shade100,
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtrados.isEmpty
                  ? const Center(child: Text("Nenhum jogo encontrado"))
                  : ListView.builder(
                itemCount: filtrados.length,
                itemBuilder: (_, i) => PreLiveCard(jogo: filtrados[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}
