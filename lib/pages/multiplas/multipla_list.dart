// lib/pages/multiplas/multipla_list.dart

import 'package:flutter/material.dart';
import 'multipla_model.dart';
import 'multipla_card.dart';

class MultiplaList extends StatelessWidget {
  final List<MultiplaSuggestion> sugestoes;
  const MultiplaList({required this.sugestoes, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sugestoes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text("⚠️ Nenhuma múltipla gerada para os critérios atuais."),
        ),
      );
    }
    return ListView.builder(
      itemCount: sugestoes.length,
      itemBuilder: (_, i) => MultiplaCard(sugestao: sugestoes[i]),
    );
  }
}
