// lib/pages/multiplas/multipla_page.dart

import 'package:flutter/material.dart';
import '../../models/fixture_prediction.dart';
import 'multipla_list.dart';
import 'multipla_model.dart';
import 'multipla_utils.dart';

class MultiplaPage extends StatefulWidget {
  final Future<List<FixturePrediction>> future;
  const MultiplaPage({required this.future, Key? key}) : super(key: key);

  @override
  State<MultiplaPage> createState() => _MultiplaPageState();
}

class _MultiplaPageState extends State<MultiplaPage> {
  late Future<List<MultiplaSuggestion>> _futureSugestoes;

  @override
  void initState() {
    super.initState();
    _futureSugestoes = _carregarSugestoes();
  }

  Future<List<MultiplaSuggestion>> _carregarSugestoes() async {
    final jogos = await widget.future;
    final agora = DateTime.now();

    final futuros = jogos.where((j) =>
    j.home != 'Sem time' &&
        j.away != 'Sem time' &&
        j.date.isAfter(agora)
    ).toList();

    return gerarCombinacoesInteligente(
      futuros,
      dcThreshold: 65.0,
      ouThreshold: 50.0,
      maxLegs: 16,
      maxSugestoes: 6,
      oddMinima: 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MultiplaSuggestion>>(
      future: _futureSugestoes,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro ao carregar múltiplas: ${snap.error}'));
        }
        final lista = snap.data ?? [];
        return MultiplaList(sugestoes: lista);
      },
    );
  }
}
