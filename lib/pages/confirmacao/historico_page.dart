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
  List<FixturePrediction> _preLiveDoDia = [];

  @override
  void initState() {
    super.initState();
    _carregarDatasSalvas();
  }

  Future<void> _carregarDatasSalvas() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final datas = <String>{};
    for (var k in keys) {
      if (k.startsWith('prelive_')) {
        datas.add(k.replaceFirst('prelive_', ''));
      }
    }

    final lista = datas.toList()..sort((a, b) => b.compareTo(a));
    setState(() => _datasDisponiveis = lista);
  }

  Future<void> _carregarDadosDoDia(String data) async {
    final prefs = await SharedPreferences.getInstance();
    final preRaw = prefs.getString('prelive_$data');
    final preList = preRaw != null
        ? (jsonDecode(preRaw) as List)
        .map((e) => FixturePrediction.fromJson(e))
        .where((m) => m.statusShort == "FT")
        .toList()
        : <FixturePrediction>[];

    setState(() {
      _dataSelecionada = data;
      _preLiveDoDia = preList;
    });
  }

  Widget _buildResumo(FixturePrediction m) {
    final principal = _getMelhorEntrada(m);
    final dica = m.advice;

    final golsCasaReal = m.golsCasa;
    final golsForaReal = m.golsFora;

    final casa = golsCasaReal ?? m.xgHome.toInt();
    final fora = golsForaReal ?? m.xgAway.toInt();
    final fonte = (golsCasaReal != null && golsForaReal != null) ? "✅FT" : "🟢XG";

    final statusPrincipal = validarTip(
      estrategia: principal.label,
      golsCasa: casa,
      golsFora: fora,
      nomeCasa: m.home,
      nomeFora: m.away,
    );
    final statusDica = validarTip(
      estrategia: dica,
      golsCasa: casa,
      golsFora: fora,
      nomeCasa: m.home,
      nomeFora: m.away,
    );

    final cor1 = _getCor(statusPrincipal);
    final cor2 = _getCor(statusDica);
    final match = "${m.home} x ${m.away}";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text("🏟️ $match"),
        subtitle: Text(
          "$fonte\n📌 Principal: ${principal.label} ($statusPrincipal)\n📌 Dica: $dica ($statusDica)",
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusPrincipal, style: TextStyle(color: cor1)),
            Text(statusDica, style: TextStyle(color: cor2)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  _EntradaSugestao _getMelhorEntrada(FixturePrediction m) {
    final op = {
      'Casa vence': m.homePct,
      'Empate': (100 - m.homePct - m.awayPct).clamp(0, 100).toDouble(),
      'Fora vence': m.awayPct,
      if (m.doubleChance.isNotEmpty)
        'Dupla Chance: ${m.doubleChance}': m.doubleChancePct,
      if (m.over25Label != null && m.over25Pct != null)
        m.over25Label!: m.over25Pct!,
      if (m.under25Label != null && m.under25Pct != null)
        m.under25Label!: m.under25Pct!,
      if (m.ambosMarcamLabel != null && m.ambosMarcamPct != null)
        m.ambosMarcamLabel!: m.ambosMarcamPct!,
      'Over 1.5': m.over15,
    };

    final sorted = op.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = sorted.first;

    return _EntradaSugestao(best.key, best.value);
  }

  Color _getCor(String status) {
    switch (status) {
      case "GREEN":
        return Colors.green.shade800;
      case "RED":
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📜 Histórico')),
      body: Column(
        children: [
          if (_datasDisponiveis.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('⚠️ Nenhum histórico encontrado.'),
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
                  if (v != null) _carregarDadosDoDia(v);
                },
              ),
            ),
          if (_dataSelecionada != null)
            Expanded(
              child: _preLiveDoDia.isEmpty
                  ? const Center(child: Text('Nenhum jogo encontrado nesse dia.'))
                  : ListView.builder(
                itemCount: _preLiveDoDia.length,
                itemBuilder: (ctx, i) => _buildResumo(_preLiveDoDia[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntradaSugestao {
  final String label;
  final double pct;
  _EntradaSugestao(this.label, this.pct);
}
