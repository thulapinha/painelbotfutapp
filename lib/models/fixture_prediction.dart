class FixturePrediction {
  final int id;
  final String home;
  final String away;
  final DateTime date;
  final double homePct;
  final double awayPct;

  // 🧠 Texto da dica e sua confiança
  final String advice;
  final double advicePct;

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

  // ✅ Resultado final do jogo
  final int? golsCasa;
  final int? golsFora;

  FixturePrediction({
    required this.id,
    required this.home,
    required this.away,
    required this.date,
    required this.homePct,
    required this.awayPct,
    required this.advice,
    required this.advicePct,
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
    this.golsCasa,
    this.golsFora,
  });

  factory FixturePrediction.fromApiJson(
      Map<String, dynamic> fx,
      Map<String, dynamic> resp,
      ) {
    final p = resp['predictions'] as Map<String, dynamic>;
    final percent = p['percent'] as Map<String, dynamic>? ?? {};

    double parsePct(dynamic v) {
      if (v == null) return 0;
      return double.tryParse(v.toString().replaceAll('%', '').trim()) ?? 0;
    }

    final adviceText = (p['advice'] as String?) ?? '';
    final advicePctVal = parsePct(p['advice_pct'] ?? p['advicePct'] ?? 0);

    final home = fx['teams']['home']['name'] as String;
    final away = fx['teams']['away']['name'] as String;
    final date = DateTime.parse(fx['fixture']['date'] as String).toLocal();

    final fStatus = fx['fixture']['status'] as Map<String, dynamic>? ?? {};
    final short = fStatus['short'] as String?;
    final elapsed = fStatus['elapsed'] as int?;

    final over15 = double.tryParse(
        p['under_over']?['goals']?['over_1_5']?['percentage']?.toString() ?? '0') ??
        0;
    final xgHome = double.tryParse(
        p['xGoals']?['home']?['total']?.toString() ?? '0') ??
        0;
    final xgAway = double.tryParse(
        p['xGoals']?['away']?['total']?.toString() ?? '0') ??
        0;

    final dc = p['doubleChance']?['label']?.toString() ?? '';
    final dcPct = double.tryParse(
        p['doubleChance']?['percentage']?.toString() ?? '0') ??
        0;

    final over25Label = p['under_over']?['goals']?['over_2_5']?['label']?.toString();
    final over25Pct = double.tryParse(
      p['under_over']?['goals']?['over_2_5']?['percentage']?.toString() ?? '0',
    );

    final under25Label = p['under_over']?['goals']?['under_2_5']?['label']?.toString();
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
      advice: adviceText,
      advicePct: advicePctVal,
      secondaryAdvice: p['secondaryAdvice'] as String?,
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
      golsCasa: null,
      golsFora: null,
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
      advicePct: (json['advicePct'] ?? 0).toDouble(),
      secondaryAdvice: json['secondaryAdvice'] as String?,
      statusShort: json['statusShort'] as String?,
      elapsedTime: json['elapsedTime'] as int?,
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
      golsCasa: json['golsCasa'] as int?,
      golsFora: json['golsFora'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'home': home,
    'away': away,
    'date': date.toIso8601String(),
    'homePct': homePct,
    'awayPct': awayPct,
    'advice': advice,
    'advicePct': advicePct,
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
    'golsCasa': golsCasa,
    'golsFora': golsFora,
  };
}
