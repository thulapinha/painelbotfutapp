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
    return await gerarCombinacoes(jogos);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MultiplaSuggestion>>(
      future: _futureSugestoes,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro ao carregar: ${snap.error}'));
        }

        final lista = snap.data ?? [];
        return MultiplaList(sugestoes: lista);
      },
    );
  }
}
