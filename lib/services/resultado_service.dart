import '../models/fixture_prediction.dart';
import '../utils/validator_util.dart';
import 'pre_live_service.dart';
import 'football_api_service.dart';

class ResultadoService {
  static Future<List<FixturePrediction>> getFinalizadosCorrigidos() async {
    final previsoes = await PreLiveService.getPreLive();

    // traz lista “do dia” e mapeia por ID
    final fixtures = await FootballApiService.getTodayFixtures();
    final mapById = <int, Map<String, dynamic>>{};
    for (final fx in fixtures.whereType<Map<String, dynamic>>()) {
      final rawId = fx['fixture']?['id'];
      final id = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (id != null) mapById[id] = fx;
    }

    final List<FixturePrediction> resultado = [];

    for (var p in previsoes) {
      Map<String, dynamic>? fx = mapById[p.id];

      // fallback se não achar “no dia”
      if (fx == null) fx = await FootballApiService.getFixture(p.id);

      if (fx == null) continue;
      final st = fx['fixture']?['status']?['short']?.toString();
      if (st != 'FT') continue;

      final goals = fx['goals'] as Map<String, dynamic>? ?? {};
      p.golsCasa = int.tryParse(goals['home']?.toString() ?? '') ?? 0;
      p.golsFora = int.tryParse(goals['away']?.toString() ?? '') ?? 0;
      p.statusShort = st;

      // aqui preenche o statusCorrigido
      p.statusCorrigido = validarTip(
        estrategia: p.advice,
        golsCasa: p.golsCasa!,
        golsFora: p.golsFora!,
        nomeCasa: p.home,
        nomeFora: p.away,
      );

      resultado.add(p);
    }

    return resultado;
  }
}
