import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction.dart';
import 'football_api_service.dart';

class PreLiveService {
  static const _cacheFixturesKey = 'pre_live_data';
  static const _cacheDateKey = 'pre_live_date';
  static const _cachePredKey = 'pred_'; // pred_{fixtureId}_{date}

  static List<FixturePrediction>? _memoryCache;
  static String? _memoryDate;

  static Future<List<FixturePrediction>> getPreLive({
    bool forceRefresh = false,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final prefs = await SharedPreferences.getInstance();

    // ✅ 1) Cache em memória
    if (!forceRefresh && _memoryCache != null && _memoryDate == today) {
      return _memoryCache!;
    }

    // ✅ 2) Cache em SharedPreferences
    final savedDate = prefs.getString(_cacheDateKey);
    if (!forceRefresh && savedDate == today) {
      final raw = prefs.getString(_cacheFixturesKey);
      if (raw != null) {
        final decoded = json.decode(raw) as List<dynamic>;
        final list = decoded
            .cast<Map<String, dynamic>>()
            .map((e) => FixturePrediction.fromJson(e))
            .toList();
        _memoryCache = list;
        _memoryDate = today;
        print("📦 PreLiveService: carregou ${list.length} jogos do cache SPrefs");
        return list;
      }
    }

    // ✅ 3) Busca da API
    final fixtures = await FootballApiService.getTodayFixtures();
    print("✅ PreLiveService: fixtures retornadas: ${fixtures.length}");

    final list = <FixturePrediction>[];
    for (final fx in fixtures) {
      final fixtureMap = fx as Map<String, dynamic>;
      final id = fixtureMap['fixture']?['id'] as int? ?? 0;

      // ✅ 3.1) Busca a predição com cache local
      final keyPred = '$_cachePredKey${id}_$today';
      final predRaw = prefs.getString(keyPred);
      Map<String, dynamic> p;
      if (predRaw != null && !forceRefresh) {
        p = json.decode(predRaw) as Map<String, dynamic>;
      } else {
        final apiPred = await FootballApiService.getPrediction(id);
        p = apiPred ?? <String, dynamic>{};
        await prefs.setString(keyPred, json.encode(p));
      }

      // ✅ 3.2) Combina fixture completo + predição
      final obj = FixturePrediction.fromApiJson(fixtureMap, p);

      // ✅ 3.3) Preenche gols se disponíveis
      final goalsMap = fixtureMap['goals'] as Map<String, dynamic>?;
      int? parseGoal(dynamic raw) =>
          raw is int ? raw : int.tryParse('$raw');
      obj.golsCasa = parseGoal(goalsMap?['home']);
      obj.golsFora = parseGoal(goalsMap?['away']);

      list.add(obj);
    }

    // ✅ 4) Salva lista + data
    final rawFixtures = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheFixturesKey, rawFixtures);
    await prefs.setString(_cacheDateKey, today);
    _memoryCache = list;
    _memoryDate = today;

    print("✅ PreLiveService: salvou ${list.length} jogos no cache SPrefs");

    return list;
  }
}
