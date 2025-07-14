class FixturePrediction {
  final int id;
  final String home;
  final String away;
  final DateTime date;
  final double homePct;
  final double awayPct;
  final String advice;

  // 🔄 LivePage
  final String? statusShort;
  final int? elapsedTime;
  final double over15;
  final double xgHome;
  final double xgAway;

  // 🟢 MultiplaPage – Dupla Chance
  final String doubleChance;
  final double doubleChancePct;

  // 📌 Estratégia complementar
  final String? secondaryAdvice;

  // 📊 Estratégias alternativas
  final String? over25Label;
  final double? over25Pct;

  final String? under25Label;
  final double? under25Pct;

  final String? ambosMarcamLabel;
  final double? ambosMarcamPct;

  FixturePrediction({
    required this.id,
    required this.home,
    required this.away,
    required this.date,
    required this.homePct,
    required this.awayPct,
    required this.advice,
    this.secondaryAdvice,
    this.statusShort,
    this.elapsedTime,
    required this.over15,
    required this.xgHome,
    required this.xgAway,
    required this.doubleChance,
    required this.doubleChancePct,
    this.over25Label,
    this.over25Pct,
    this.under25Label,
    this.under25Pct,
    this.ambosMarcamLabel,
    this.ambosMarcamPct,
  });

  factory FixturePrediction.fromApiJson(
    Map<String, dynamic> fx,
    Map<String, dynamic> resp,
  ) {
    final home = fx['teams']['home']['name'] as String;
    final away = fx['teams']['away']['name'] as String;
    final date = DateTime.parse(fx['fixture']['date'] as String).toLocal();

    final fStatus = fx['fixture']['status'] as Map<String, dynamic>? ?? {};
    final short = fStatus['short'] as String?;
    final elapsed = fStatus['elapsed'] as int?;

    final p = resp['predictions'] as Map<String, dynamic>;
    final percent = p['percent'] as Map<String, dynamic>? ?? {};

    double parsePct(dynamic v) {
      if (v == null) return 0;
      final s = v.toString().replaceAll('%', '').trim();
      return double.tryParse(s) ?? 0;
    }

    final over15 =
        double.tryParse(
          p['under_over']?['goals']?['over_1_5']?['percentage']?.toString() ??
              '0',
        ) ??
        0;

    final xgHome =
        double.tryParse(p['xGoals']?['home']?['total']?.toString() ?? '0') ?? 0;

    final xgAway =
        double.tryParse(p['xGoals']?['away']?['total']?.toString() ?? '0') ?? 0;

    final dc = p['doubleChance']?['label']?.toString() ?? '';
    final dcPct =
        double.tryParse(p['doubleChance']?['percentage']?.toString() ?? '0') ??
        0;

    final secondaryAdvice =
        p['under_over']?['goals']?['over_2_5']?['label']?.toString() ?? dc;

    final over25Label = p['under_over']?['goals']?['over_2_5']?['label']
        ?.toString();
    final over25Pct = double.tryParse(
      p['under_over']?['goals']?['over_2_5']?['percentage']?.toString() ?? '0',
    );

    final under25Label = p['under_over']?['goals']?['under_2_5']?['label']
        ?.toString();
    final under25Pct = double.tryParse(
      p['under_over']?['goals']?['under_2_5']?['percentage']?.toString() ?? '0',
    );

    final ambosLabel = p['goals']?['both']?['teams']?['label']?.toString();
    final ambosPct = double.tryParse(
      p['goals']?['both']?['teams']?['percentage']?.toString() ?? '0',
    );

    return FixturePrediction(
      id: fx['fixture']['id'] as int,
      home: home,
      away: away,
      date: date,
      homePct: parsePct(percent['home']),
      awayPct: parsePct(percent['away']),
      advice: (p['advice'] as String?) ?? '',
      secondaryAdvice: secondaryAdvice,
      statusShort: short,
      elapsedTime: elapsed,
      over15: over15,
      xgHome: xgHome,
      xgAway: xgAway,
      doubleChance: dc,
      doubleChancePct: dcPct,
      over25Label: over25Label,
      over25Pct: over25Pct,
      under25Label: under25Label,
      under25Pct: under25Pct,
      ambosMarcamLabel: ambosLabel,
      ambosMarcamPct: ambosPct,
    );
  }

  factory FixturePrediction.fromJson(Map<String, dynamic> json) {
    return FixturePrediction(
      id: json['id'] as int,
      home: json['home'] as String,
      away: json['away'] as String,
      date: DateTime.parse(json['date'] as String),
      homePct: (json['homePct'] ?? 0).toDouble(),
      awayPct: (json['awayPct'] ?? 0).toDouble(),
      advice: json['advice'] ?? '',
      secondaryAdvice: json['secondaryAdvice'] as String?,
      statusShort: json['statusShort'],
      elapsedTime: json['elapsedTime'],
      over15: (json['over15'] ?? 0).toDouble(),
      xgHome: (json['xgHome'] ?? 0).toDouble(),
      xgAway: (json['xgAway'] ?? 0).toDouble(),
      doubleChance: json['doubleChance'] ?? '',
      doubleChancePct: (json['doubleChancePct'] ?? 0).toDouble(),
      over25Label: json['over25Label'] as String?,
      over25Pct: (json['over25Pct'] as num?)?.toDouble(),
      under25Label: json['under25Label'] as String?,
      under25Pct: (json['under25Pct'] as num?)?.toDouble(),
      ambosMarcamLabel: json['ambosMarcamLabel'] as String?,
      ambosMarcamPct: (json['ambosMarcamPct'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home': home,
      'away': away,
      'date': date.toIso8601String(),
      'homePct': homePct,
      'awayPct': awayPct,
      'advice': advice,
      'secondaryAdvice': secondaryAdvice,
      'statusShort': statusShort,
      'elapsedTime': elapsedTime,
      'over15': over15,
      'xgHome': xgHome,
      'xgAway': xgAway,
      'doubleChance': doubleChance,
      'doubleChancePct': doubleChancePct,
      'over25Label': over25Label,
      'over25Pct': over25Pct,
      'under25Label': under25Label,
      'under25Pct': under25Pct,
      'ambosMarcamLabel': ambosMarcamLabel,
      'ambosMarcamPct': ambosMarcamPct,
    };
  }
}
