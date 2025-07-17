import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction.dart';
import 'football_api_service.dart';

class ResultadoService {
  static Future<List<FixturePrediction>> getFinalizadosCorrigidos() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final raw = prefs.getString('prelive_$today');
    if (raw == null) return [];

    final previsoes = (jsonDecode(raw) as List)
        .map((e) => FixturePrediction.fromJson(e))
        .toList();

    final fixtures = await FootballApiService.getTodayFixtures();
    final mapById = {
      for (var fx in fixtures) fx['fixture']['id'] as int: fx
    };

    for (var p in previsoes) {
      final fx = mapById[p.id];
      if (fx != null) {
        // status mutável
        p.statusShort = (fx['fixture']['status'] as Map<String, dynamic>)['short'] as String?;
        if (p.statusShort == 'FT') {
          final goals = fx['goals'] as Map<String, dynamic>?;
          p.golsCasa = int.tryParse(goals?['home']?.toString() ?? '') ?? 0;
          p.golsFora = int.tryParse(goals?['away']?.toString() ?? '') ?? 0;
        }
      }
    }

    return previsoes.where((p) =>
    p.statusShort == 'FT' &&
        p.golsCasa != null &&
        p.golsFora != null
    ).toList();
  }
}
