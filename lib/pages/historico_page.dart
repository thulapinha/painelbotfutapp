import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({Key? key}) : super(key: key);

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<String> _datasDisponiveis = [];
  String? _dataSelecionada;
  List<FixturePrediction> _preLiveDoDia = [];
  List<Map<String, dynamic>> _reportDoDia = [];

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
      if (k.startsWith('report_')) {
        datas.add(k.replaceFirst('report_', ''));
      }
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
              .toList()
        : <FixturePrediction>[];

    final reportRaw = prefs.getString('report_$data');
    final reportList = reportRaw != null
        ? (jsonDecode(reportRaw) as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _dataSelecionada = data;
      _preLiveDoDia = preList;
      _reportDoDia = reportList;
    });
  }

  Widget _buildResumo(FixturePrediction m) {
    final encontrado = _reportDoDia.firstWhere(
      (r) =>
          (r['match'] as String).contains(m.home) &&
          (r['match'] as String).contains(m.away),
      orElse: () => {},
    );

    final principal = _getMelhorEntrada(m);
    final extra = m.secondaryAdvice;
    final match = "${m.home} x ${m.away}";

    final res1 = encontrado['result'] ?? '⏳';
    final motivo1 = encontrado['reason'] ?? 'Aguardando confirmação';
    final res2 = encontrado['result_extra'] ?? '⏳';
    final motivo2 = encontrado['reason_extra'] ?? '';

    final cor1 = res1.toString().contains('GREEN')
        ? Colors.green
        : res1.toString().contains('RED')
        ? Colors.red
        : Colors.grey;

    final cor2 = res2.toString().contains('GREEN')
        ? Colors.green
        : res2.toString().contains('RED')
        ? Colors.red
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text("🏟️ $match"),
        subtitle: Text(
          "📌 Principal: ${principal.label} (${res1})\n📝 $motivo1\n📌 Extra: $extra (${res2})${motivo2.isNotEmpty ? "\n📝 $motivo2" : ""}",
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              res1.toString(),
              style: TextStyle(color: cor1, fontWeight: FontWeight.bold),
            ),
            Text(
              res2.toString(),
              style: TextStyle(color: cor2, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  _EntradaSugestao _getMelhorEntrada(FixturePrediction m) {
    final op = {'Casa vence': m.homePct, 'Fora vence': m.awayPct};
    final best = op.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return _EntradaSugestao(best.key, best.value);
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
                  ? const Center(
                      child: Text('Nenhum jogo encontrado nesse dia.'),
                    )
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
