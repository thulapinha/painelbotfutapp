import 'package:flutter/material.dart';
import '../utils/parser_mensagem.dart';
import '../services/radar_service.dart';

class BuscaEventoPage extends StatefulWidget {
  const BuscaEventoPage({Key? key}) : super(key: key);

  @override
  State<BuscaEventoPage> createState() => _BuscaEventoPageState();
}

class _BuscaEventoPageState extends State<BuscaEventoPage> {
  final _controller = TextEditingController();
  List<EventoRadar> _resultados = [];
  MensagemCorner? _msg;
  bool _carregando = false;
  String? _erro;

  Future<void> _processar() async {
    final texto = _controller.text;
    final dados = extrairCornerProbet(texto);
    if (dados == null) {
      setState(() => _erro = "Não consegui extrair os dados.");
      return;
    }

    setState(() {
      _msg = dados;
      _carregando = true;
      _erro = null;
      _resultados = [];
    });

    try {
      final termoBusca = "${dados.timeA} ${dados.timeB}";
      final eventos = await RadarService.buscarEvento(termoBusca);
      setState(() => _resultados = eventos);
    } catch (e) {
      setState(() => _erro = "Erro: $e");
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🕵️‍♂️ Mensagem & Radar API")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Cole mensagem da CornerProbet aqui',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Extrair e buscar evento"),
              onPressed: _processar,
            ),
            const SizedBox(height: 12),
            if (_carregando) const CircularProgressIndicator(),
            if (_erro != null) Text(_erro!, style: const TextStyle(color: Colors.red)),
            if (_msg != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🏟 Jogo: ${_msg!.timeA} x ${_msg!.timeB}"),
                      Text("🏆 Competição: ${_msg!.competencia}"),
                      Text("⏱ Tempo: ${_msg!.minuto}  |  Placar: ${_msg!.score}"),
                      Text("📊 Link análise: ${_msg!.urlCorner}"),
                      Text("🎰 Casa aposta: ${_msg!.urlCasaAposta}"),
                    ],
                  ),
                ),
              ),
            if (_resultados.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _resultados.length,
                  itemBuilder: (_, i) {
                    final ev = _resultados[i];
                    final url = "https://bet365.bet.br/#/AX/K^${ev.name.replaceAll(' ', '_')}/";
                    return Card(
                      child: ListTile(
                        title: Text(ev.name),
                        subtitle: Text("${ev.date}  |  ${ev.league}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_browser),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("🔗 URL gerado: $url")),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
