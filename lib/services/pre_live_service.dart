import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction.dart';
import 'football_api_service.dart';

class PreLiveService {
  static const _cacheKey = 'pre_live_data';
  static const _cacheDateKey = 'pre_live_date';
  static List<FixturePrediction>? _memoryCache;
  static String? _memoryDate;

  static Future<List<FixturePrediction>> getPreLive({
    bool forceRefresh = false,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    // 1) Cache em memória
    if (!forceRefresh && _memoryCache != null && _memoryDate == today) {
      return _memoryCache!;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_cacheDateKey);

    // 2) Cache em SharedPreferences
    if (!forceRefresh && _memoryCache == null && savedDate == today) {
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final list = (json.decode(raw) as List<dynamic>)
            .map((e) => FixturePrediction.fromJson(e as Map<String, dynamic>))
            .toList();
        _memoryCache = list;
        _memoryDate = today;
        return list;
      }
    }

    // 3) Buscar TODOS os jogos de hoje
    final fixtures = await FootballApiService.getTodayFixtures();
    final preds = <FixturePrediction>[];

    for (final fx in fixtures) {
      final id = fx['fixture']['id'] as int;
      final predJson = await FootballApiService.getPrediction(id);
      if (predJson == null) continue;

      final p = FixturePrediction.fromApiJson(
        fx as Map<String, dynamic>,
        predJson,
      );

      // se o JSON já trouxe gols, preenche aqui
      final goals = fx['goals'] as Map<String, dynamic>?;
      if (goals != null) {
        p.golsCasa = goals['home'] as int?;
        p.golsFora = goals['away'] as int?;
      }

      preds.add(p);
    }

    // 4) Salvar cache
    final rawJson = json.encode(preds.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, rawJson);
    await prefs.setString(_cacheDateKey, today);

    _memoryCache = preds;
    _memoryDate = today;

    // 5) Histórico diário
    await prefs.setString('prelive_$today', rawJson);

    return preds;
  }
}
