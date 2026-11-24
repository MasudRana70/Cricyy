// lib/models/player_model.dart

class PlayerModel {
  final String id;
  final String name;
  final String? shortName;
  final String? profileImage;
  final bool isActive;

  const PlayerModel({
    required this.id,
    required this.name,
    this.shortName,
    this.profileImage,
    this.isActive = true,
  });

  String get displayName => shortName ?? name;

  factory PlayerModel.fromJson(Map<String, dynamic> json) => PlayerModel(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    shortName: json['shortName'],
    profileImage: json['profileImage'],
    isActive: json['isActive'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (shortName != null) 'shortName': shortName,
  };
}

// ── Batting Stats ─────────────────────────────────────────────────────────────
class BattingStats {
  final int totalMatches;
  final int battingInnings;
  final int totalRuns;
  final int highestScore;
  final int notOuts;
  final double? battingAverage;
  final double strikeRate;
  final int totalBalls;
  final int totalFours;
  final int totalSixes;
  final int halfCenturies;
  final int centuries;

  const BattingStats({
    required this.totalMatches,
    required this.battingInnings,
    required this.totalRuns,
    required this.highestScore,
    required this.notOuts,
    this.battingAverage,
    required this.strikeRate,
    required this.totalBalls,
    required this.totalFours,
    required this.totalSixes,
    required this.halfCenturies,
    required this.centuries,
  });

  factory BattingStats.fromJson(Map<String, dynamic> json) => BattingStats(
    totalMatches:   json['totalMatches']   ?? 0,
    battingInnings: json['battingInnings'] ?? 0,
    totalRuns:      json['totalRuns']      ?? 0,
    highestScore:   json['highestScore']   ?? 0,
    notOuts:        json['notOuts']        ?? 0,
    battingAverage: (json['battingAverage'] as num?)?.toDouble(),
    strikeRate:     (json['strikeRate']    as num?)?.toDouble() ?? 0,
    totalBalls:     json['totalBalls']     ?? 0,
    totalFours:     json['totalFours']     ?? 0,
    totalSixes:     json['totalSixes']     ?? 0,
    halfCenturies:  json['halfCenturies']  ?? 0,
    centuries:      json['centuries']      ?? 0,
  );

  static BattingStats empty() => const BattingStats(
    totalMatches: 0, battingInnings: 0, totalRuns: 0, highestScore: 0,
    notOuts: 0, strikeRate: 0, totalBalls: 0, totalFours: 0,
    totalSixes: 0, halfCenturies: 0, centuries: 0,
  );
}

// ── Bowling Stats ─────────────────────────────────────────────────────────────
class BowlingStats {
  final int bowlingMatches;
  final int bowlingInnings;
  final int totalLegalBalls;
  final double overs;
  final int maidens;
  final int totalRunsConceded;
  final int totalWickets;
  final double? bowlingAverage;
  final double economyRate;
  final double? bowlingStrikeRate;
  final String? bestBowling;
  final int threeWicketHauls;
  final int fourWicketHauls;
  final int fiveWicketHauls;

  const BowlingStats({
    required this.bowlingMatches,
    required this.bowlingInnings,
    required this.totalLegalBalls,
    required this.overs,
    required this.maidens,
    required this.totalRunsConceded,
    required this.totalWickets,
    this.bowlingAverage,
    required this.economyRate,
    this.bowlingStrikeRate,
    this.bestBowling,
    required this.threeWicketHauls,
    required this.fourWicketHauls,
    required this.fiveWicketHauls,
  });

  factory BowlingStats.fromJson(Map<String, dynamic> json) => BowlingStats(
    bowlingMatches:    json['bowlingMatches']    ?? 0,
    bowlingInnings:    json['bowlingInnings']    ?? 0,
    totalLegalBalls:   json['totalLegalBalls']   ?? 0,
    overs:            (json['overs']            as num?)?.toDouble() ?? 0,
    maidens:           json['maidens']           ?? 0,
    totalRunsConceded: json['totalRunsConceded'] ?? 0,
    totalWickets:      json['totalWickets']      ?? 0,
    bowlingAverage:   (json['bowlingAverage']   as num?)?.toDouble(),
    economyRate:      (json['economyRate']       as num?)?.toDouble() ?? 0,
    bowlingStrikeRate:(json['bowlingStrikeRate'] as num?)?.toDouble(),
    bestBowling:       json['bestBowling'],
    threeWicketHauls:  json['threeWicketHauls']  ?? 0,
    fourWicketHauls:   json['fourWicketHauls']   ?? 0,
    fiveWicketHauls:   json['fiveWicketHauls']   ?? 0,
  );

  static BowlingStats empty() => const BowlingStats(
    bowlingMatches: 0, bowlingInnings: 0, totalLegalBalls: 0, overs: 0,
    maidens: 0, totalRunsConceded: 0, totalWickets: 0, economyRate: 0,
    threeWicketHauls: 0, fourWicketHauls: 0, fiveWicketHauls: 0,
  );
}
