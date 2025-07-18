class FixturePrediction {
  final int id;
  final String home;
  final String away;
  final DateTime date;
  final double homePct;
  final double awayPct;
  final String advice;
  final double advicePct;
  String? statusShort;
  int? elapsedTime;
  final double over15;
  final double xgHome;
  final double xgAway;
  final String doubleChance;
  final double doubleChancePct;
  final String? secondaryAdvice;
  final String? over25Label;
  final double? over25Pct;
  final String? under25Label;
  final double? under25Pct;
  final String? ambosMarcamLabel;
  final double? ambosMarcamPct;
  int? golsCasa;
  int? golsFora;
  String? statusCorrigido; // ✔️ novo campo para GREEN/RED/VOID

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
    this.statusCorrigido, // ✔️ incluído no construtor
  });

  factory FixturePrediction.fromApiJson(
      Map<String, dynamic> fx,
      Map<String, dynamic> p,
      ) {
    final pred = p['predictions'] as Map<String, dynamic>? ?? {};
    final fixtureMap = fx['fixture'] as Map<String, dynamic>? ?? {};
    final teamsMap = fx['teams'] as Map<String, dynamic>? ?? {};
    final homeName = teamsMap['home']?['name']?.toString() ?? 'Sem time';
    final awayName = teamsMap['away']?['name']?.toString() ?? 'Sem time';
    final fixtureId = fixtureMap['id'] as int? ?? 0;

    final rawDate = fixtureMap['date']?.toString();
    DateTime date = DateTime.now();
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        date = DateTime.parse(rawDate).toLocal();
      } catch (_) {}
    }

    final statusMap = fixtureMap['status'] as Map<String, dynamic>? ?? {};
    final shortStatus = statusMap['short'] as String?;
    final elapsed = statusMap['elapsed'] as int?;

    final percent = pred['percent'] as Map<String, dynamic>? ?? {};
    double parsePct(dynamic v) => double.tryParse(v.toString().replaceAll('%', '').trim()) ?? 0;
    final homeP = parsePct(percent['home']);
    final drawP = parsePct(percent['draw']);
    final awayP = parsePct(percent['away']);

    final adviceText = pred['advice']?.toString() ?? '';
    final adviceLower = adviceText.toLowerCase();
    double advicePctVal = 0;

    if (adviceLower.contains('double') && adviceLower.contains(homeName.toLowerCase())) {
      advicePctVal = homeP + drawP;
    } else if (adviceLower.contains('double') && adviceLower.contains(awayName.toLowerCase())) {
      advicePctVal = awayP + drawP;
    } else if (adviceLower.contains(homeName.toLowerCase())) {
      advicePctVal = homeP;
    } else if (adviceLower.contains(awayName.toLowerCase())) {
      advicePctVal = awayP;
    } else {
      advicePctVal = drawP;
    }

    final underOver = pred['under_over']?.toString();
    final over15Pct = underOver == '+1.5' ? 70.0 : 0.0;
    final o25Label = underOver == '+2.5' ? 'Over 2.5' : null;
    final o25Pct = o25Label != null ? 65.0 : null;
    final u25Label = underOver == '-2.5' ? 'Under 2.5' : null;
    final u25Pct = u25Label != null ? 60.0 : null;

    final xgH = parsePct(pred['goals']?['home']);
    final xgA = parsePct(pred['goals']?['away']);

    final dcLabel = pred['winner']?['comment']?.toString() ?? '';
    final dcPctVal = (homeP + drawP >= awayP + drawP) ? homeP + drawP : awayP + drawP;

    final ambosMarcamLabel = null;
    final ambosMarcamPct = null;

    final goalsMap = fx['goals'] as Map<String, dynamic>?;
    int? parseGoal(dynamic raw) => raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    final homeGoals = parseGoal(goalsMap?['home']);
    final awayGoals = parseGoal(goalsMap?['away']);

    return FixturePrediction(
      id: fixtureId,
      home: homeName,
      away: awayName,
      date: date,
      homePct: homeP,
      awayPct: awayP,
      advice: adviceText,
      advicePct: advicePctVal,
      secondaryAdvice: pred['secondaryAdvice']?.toString(),
      statusShort: shortStatus,
      elapsedTime: elapsed,
      over15: over15Pct,
      xgHome: xgH,
      xgAway: xgA,
      doubleChance: dcLabel,
      doubleChancePct: dcPctVal,
      over25Label: o25Label,
      over25Pct: o25Pct,
      under25Label: u25Label,
      under25Pct: u25Pct,
      ambosMarcamLabel: ambosMarcamLabel,
      ambosMarcamPct: ambosMarcamPct,
      golsCasa: homeGoals,
      golsFora: awayGoals,
      statusCorrigido: null, // ← inicializa como null
    );
  }

  factory FixturePrediction.fromJson(Map<String, dynamic> json) {
    return FixturePrediction(
      id: json['id'] as int,
      home: json['home'] as String,
      away: json['away'] as String,
      date: DateTime.parse(json['date'] as String),
      homePct: (json['homePct'] as num? ?? 0).toDouble(),
      awayPct: (json['awayPct'] as num? ?? 0).toDouble(),
      advice: json['advice'] as String? ?? '',
      advicePct: (json['advicePct'] as num? ?? 0).toDouble(),
      secondaryAdvice: json['secondaryAdvice'] as String?,
      statusShort: json['statusShort'] as String?,
      elapsedTime: json['elapsedTime'] as int?,
      over15: (json['over15'] as num? ?? 0).toDouble(),
      xgHome: (json['xgHome'] as num? ?? 0).toDouble(),
      xgAway: (json['xgAway'] as num? ?? 0).toDouble(),
      doubleChance: json['doubleChance'] as String? ?? '',
      doubleChancePct: (json['doubleChancePct'] as num? ?? 0).toDouble(),
      over25Label: json['over25Label'] as String?,
      over25Pct: (json['over25Pct'] as num?)?.toDouble(),
      under25Label: json['under25Label'] as String?,
      under25Pct: (json['under25Pct'] as num?)?.toDouble(),
      ambosMarcamLabel: json['ambosMarcamLabel'] as String?,
      ambosMarcamPct: (json['ambosMarcamPct'] as num?)?.toDouble(),
      golsCasa: json['golsCasa'] as int?,
      golsFora: json['golsFora'] as int?,
      statusCorrigido: json['statusCorrigido'] as String?, // ✔️ incluído no fromJson
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
