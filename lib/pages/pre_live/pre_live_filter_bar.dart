import 'package:flutter/material.dart';

class PreLiveFilterBar extends StatelessWidget {
  final bool mostrarSomenteFuturos;
  final VoidCallback onAtualizar;
  final ValueChanged<bool> onFiltroAlterado;

  const PreLiveFilterBar({
    required this.mostrarSomenteFuturos,
    required this.onAtualizar,
    required this.onFiltroAlterado,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Atualizar agora"),
            onPressed: onAtualizar,
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: Text(
              mostrarSomenteFuturos ? "Somente futuros" : "Todos os jogos",
            ),
            selected: mostrarSomenteFuturos,
            onSelected: onFiltroAlterado,
            selectedColor: Colors.green.shade100,
          ),
        ],
      ),
    );
  }
}
