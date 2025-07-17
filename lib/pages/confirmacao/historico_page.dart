import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/fixture_prediction.dart';
import '../../utils/validator_util.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({Key? key}) : super(key: key);

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<String> _datasDisponiveis = [];
  String? _dataSelecionada;
  List<FixturePrediction> _resultadosDoDia = [];

  @override
  void initState() {
    super.initState();
    _carregarDatasCorrigidas();
  }

  Future<void> _carregarDatasCorrigidas() async {
    final prefs = await SharedPreferences.getInstance();
    final chaves = prefs.getKeys();

    final datas = chaves
        .where((k) => k.startsWith('resultadosCorrigidos_'))
        .map((k) => k.replaceFirst('resultadosCorrigidos_', ''))
        .toList();

    datas.sort((a, b) => b.compareTo(a));
    setState(() => _datasDisponiveis = datas);
  }

  Future<void> _carregarResultadosDoDia(String data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('resultadosCorrigidos_$data');
    if (raw == null) {
      setState(() {
        _dataSelecionada = data;
        _resultadosDoDia = [];
      });
      return;
    }

    final lista = (jsonDecode(raw) as List)
        .map((e) => FixturePrediction.fromJson(e))
        .where((j) =>
    j.statusShort == 'FT' &&
        j.golsCasa != null &&
        j.golsFora != null)
        .toList();

    setState(() {
      _dataSelecionada = data;
      _resultadosDoDia = lista;
    });
  }

  Widget _buildResumo(FixturePrediction jogo) {
    final estrategia = _getMelhorEstrategia(jogo);
    final dica = jogo.advice;

    final casa = jogo.golsCasa!;
    final fora = jogo.golsFora!;
    const fonte = "✅FT";

    final statusEstrategia = validarTip(
      estrategia: estrategia.label,
      golsCasa: casa,
      golsFora: fora,
      nomeCasa: jogo.home,
      nomeFora: jogo.away,
    );

    final statusDica = validarTip(
      estrategia: dica,
      golsCasa: casa,
      golsFora: fora,
      nomeCasa: jogo.home,
      nomeFora: jogo.away,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text("🏟️ ${jogo.home} x ${jogo.away}"),
        subtitle: Text(
          "$fonte\n📌 Estratégia: ${estrategia.label} → $statusEstrategia\n📌 Dica: $dica → $statusDica",
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              statusEstrategia,
              style: TextStyle(color: _corStatus(statusEstrategia)),
            ),
            Text(
              statusDica,
              style: TextStyle(color: _corStatus(statusDica)),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  _EstrategiaSugestao _getMelhorEstrategia(FixturePrediction jogo) {
    final empatePct = (100 - jogo.homePct - jogo.awayPct).clamp(0, 100).toDouble();

    final opcoes = {
      'Casa vence': jogo.homePct,
      'Empate': empatePct,
      'Fora vence': jogo.awayPct,
      if (jogo.doubleChance.isNotEmpty)
        'Dupla Chance: ${jogo.doubleChance}': jogo.doubleChancePct,
      if (jogo.over25Label != null && jogo.over25Pct != null)
        jogo.over25Label!: jogo.over25Pct!,
      if (jogo.under25Label != null && jogo.under25Pct != null)
        jogo.under25Label!: jogo.under25Pct!,
      if (jogo.ambosMarcamLabel != null && jogo.ambosMarcamPct != null)
        jogo.ambosMarcamLabel!: jogo.ambosMarcamPct!,
      'Over 1.5': jogo.over15,
    };

    final ordenado = opcoes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final melhor = ordenado.first;

    return _EstrategiaSugestao(melhor.key, melhor.value);
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'GREEN':
        return Colors.green.shade800;
      case 'RED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📜 Histórico de Resultados')),
      body: Column(
        children: [
          if (_datasDisponiveis.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('⚠️ Nenhum histórico corrigido encontrado.'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButton<String>(
                value: _dataSelecionada,
                hint: const Text("📅 Selecione uma data"),
                isExpanded: true,
                items: _datasDisponiveis
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _carregarResultadosDoDia(v);
                },
              ),
            ),
          if (_dataSelecionada != null)
            Expanded(
              child: _resultadosDoDia.isEmpty
                  ? const Center(child: Text('Nenhum jogo finalizado nesse dia.'))
                  : ListView.builder(
                itemCount: _resultadosDoDia.length,
                itemBuilder: (ctx, i) => _buildResumo(_resultadosDoDia[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _EstrategiaSugestao {
  final String label;
  final double pct;
  _EstrategiaSugestao(this.label, this.pct);
}
