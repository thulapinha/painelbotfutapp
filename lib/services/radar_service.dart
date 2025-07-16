import 'dart:convert';
import 'package:http/http.dart' as http;

class EventoRadar {
  final String id;
  final String name;
  final String date;
  final String league;

  EventoRadar({
    required this.id,
    required this.name,
    required this.date,
    required this.league,
  });

  factory EventoRadar.fromJson(Map<String, dynamic> json) {
    return EventoRadar(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      league: json['league'] ?? '',
    );
  }
}


class RadarService {
  // Método interno que faz a requisição ao endpoint Bet365
  static Future<List<EventoRadar>> _searchBet365(String termo) async {
    final uri = Uri.https(
      'radarsport-api.vercel.app',
      '/api/bet365/info',
      {
        'locale': 'America/Buenos_Aires',
        'type': 'match_search',
        'name': Uri.encodeQueryComponent(termo),
      },
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('RadarSport API retornou ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body);
    if (body is List) {
      return body.map((e) => EventoRadar.fromJson(e)).toList();
    }
    return [];
  }

  /// Expose este método para sua BuscaEventoPage
  static Future<List<EventoRadar>> buscarEvento(String termo) {
    return _searchBet365(termo);
  }

  /// Retorna a URL oficial Bet365 para o evento que bate com data e ordem
  static Future<String?> obterLinkBet365({
    required String termo,
    required DateTime fixtureDate,
    required String home,
    required String away,
  }) async {
    final raw = await _searchBet365(termo);

    // filtrar mesmo dia
    final matchesDate = raw.where((e) {
      try {
        final d = DateTime.parse(e.date).toLocal();
        return d.year == fixtureDate.year &&
            d.month == fixtureDate.month &&
            d.day == fixtureDate.day;
      } catch (_) {
        return false;
      }
    }).toList();

    // normalizar strings para busca de "home vs away"
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    final nh = norm(home), na = norm(away);

    final matchesNames = matchesDate.where((e) {
      final n = norm(e.name);
      return n.contains('$nh vs $na') || n.contains('$nh v $na');
    }).toList();

    final chosen = matchesNames.isNotEmpty
        ? matchesNames.first
        : (matchesDate.isNotEmpty ? matchesDate.first : null);

    if (chosen == null) return null;
    return 'https://www.bet365.com/#/AC/B1/C1/D${chosen.id}/';
  }
}
