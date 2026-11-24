// lib/models/innings_model.dart

class InningsModel {
  final String id;
  final String matchId;
  final int inningsNumber;
  final String battingTeamId;
  final String battingTeamName;
  final String bowlingTeamId;
  final String bowlingTeamName;
  final int totalRuns;
  final int totalWickets;
  final int completedOvers;
  final int currentBallInOver;
  final int totalLegalBalls;
  final ExtrasBreakdown extras;
  final int? target;
  final String status;
  final List<BatterState> currentBatters;
  final List<BatterState> battersUsed;
  final List<BowlerState> bowlersUsed;
  final List<FallOfWicket> fallOfWickets;
  final List<String> thisOverBalls;
  final int thisOverRuns;

  const InningsModel({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.battingTeamName,
    required this.bowlingTeamId,
    required this.bowlingTeamName,
    required this.totalRuns,
    required this.totalWickets,
    required this.completedOvers,
    required this.currentBallInOver,
    required this.totalLegalBalls,
    required this.extras,
    this.target,
    required this.status,
    required this.currentBatters,
    required this.battersUsed,
    required this.bowlersUsed,
    required this.fallOfWickets,
    this.thisOverBalls = const [],
    this.thisOverRuns = 0,
  });

  String get oversDisplay => '$completedOvers.$currentBallInOver';
  String get scoreDisplay => '$totalRuns/$totalWickets';

  BatterState? get striker =>
      currentBatters.where((b) => b.isStriker).firstOrNull;
  BatterState? get nonStriker =>
      currentBatters.where((b) => !b.isStriker).firstOrNull;
  BowlerState? get currentBowler =>
      bowlersUsed.where((b) => b.isCurrent).firstOrNull;

  double get currentRunRate {
    if (totalLegalBalls == 0) return 0;
    return totalRuns / (totalLegalBalls / 6);
  }

  double? get requiredRunRate {
    if (target == null) return null;
    final remaining = target! - totalRuns;
    return remaining > 0 ? remaining / 1 : null;
  }

  InningsModel copyWith({
    String? id,
    String? matchId,
    int? inningsNumber,
    String? battingTeamId,
    String? battingTeamName,
    String? bowlingTeamId,
    String? bowlingTeamName,
    int? totalRuns,
    int? totalWickets,
    int? completedOvers,
    int? currentBallInOver,
    int? totalLegalBalls,
    ExtrasBreakdown? extras,
    int? target,
    String? status,
    List<BatterState>? currentBatters,
    List<BatterState>? battersUsed,
    List<BowlerState>? bowlersUsed,
    List<FallOfWicket>? fallOfWickets,
    List<String>? thisOverBalls,
    int? thisOverRuns,
  }) {
    return InningsModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      battingTeamName: battingTeamName ?? this.battingTeamName,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      bowlingTeamName: bowlingTeamName ?? this.bowlingTeamName,
      totalRuns: totalRuns ?? this.totalRuns,
      totalWickets: totalWickets ?? this.totalWickets,
      completedOvers: completedOvers ?? this.completedOvers,
      currentBallInOver: currentBallInOver ?? this.currentBallInOver,
      totalLegalBalls: totalLegalBalls ?? this.totalLegalBalls,
      extras: extras ?? this.extras,
      target: target ?? this.target,
      status: status ?? this.status,
      currentBatters: currentBatters ?? this.currentBatters,
      battersUsed: battersUsed ?? this.battersUsed,
      bowlersUsed: bowlersUsed ?? this.bowlersUsed,
      fallOfWickets: fallOfWickets ?? this.fallOfWickets,
      thisOverBalls: thisOverBalls ?? this.thisOverBalls,
      thisOverRuns: thisOverRuns ?? this.thisOverRuns,
    );
  }

  factory InningsModel.fromJson(Map<String, dynamic> json) => InningsModel(
    id:               json['_id'] ?? json['id'] ?? '',
    matchId:          json['matchId'] ?? '',
    inningsNumber:    json['inningsNumber'] ?? 1,
    battingTeamId:    json['battingTeamId'] ?? '',
    battingTeamName:  json['battingTeamName'] ?? '',
    bowlingTeamId:    json['bowlingTeamId'] ?? '',
    bowlingTeamName:  json['bowlingTeamName'] ?? '',
    totalRuns:        json['totalRuns'] ?? 0,
    totalWickets:     json['totalWickets'] ?? 0,
    completedOvers:   json['completedOvers'] ?? 0,
    currentBallInOver:json['currentBallInOver'] ?? 0,
    totalLegalBalls:  json['totalLegalBalls'] ?? 0,
    extras:  ExtrasBreakdown.fromJson(json['extras'] ?? {}),
    target:  json['target'],
    status:  json['status'] ?? 'not_started',
    currentBatters: (json['currentBatters'] as List<dynamic>? ?? [])
        .map((e) => BatterState.fromJson(e)).toList(),
    battersUsed: (json['battersUsed'] as List<dynamic>? ?? [])
        .map((e) => BatterState.fromJson(e)).toList(),
    bowlersUsed: (json['bowlersUsed'] as List<dynamic>? ?? [])
        .map((e) => BowlerState.fromJson(e)).toList(),
    fallOfWickets: (json['fallOfWickets'] as List<dynamic>? ?? [])
        .map((e) => FallOfWicket.fromJson(e)).toList(),
    thisOverBalls: (json['thisOverBalls'] as List<dynamic>? ?? [])
        .map((e) => e.toString()).toList(),
    thisOverRuns: json['thisOverRuns'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'matchId': matchId,
    'inningsNumber': inningsNumber,
    'battingTeamId': battingTeamId,
    'battingTeamName': battingTeamName,
    'bowlingTeamId': bowlingTeamId,
    'bowlingTeamName': bowlingTeamName,
    'totalRuns': totalRuns,
    'totalWickets': totalWickets,
    'completedOvers': completedOvers,
    'currentBallInOver': currentBallInOver,
    'totalLegalBalls': totalLegalBalls,
    'extras': extras.toJson(),
    if (target != null) 'target': target,
    'status': status,
    'currentBatters': currentBatters.map((e) => e.toJson()).toList(),
    'battersUsed': battersUsed.map((e) => e.toJson()).toList(),
    'bowlersUsed': bowlersUsed.map((e) => e.toJson()).toList(),
    'fallOfWickets': fallOfWickets.map((e) => e.toJson()).toList(),
    'thisOverBalls': thisOverBalls,
    'thisOverRuns': thisOverRuns,
  };
}

class BatterState {
  final String playerId;
  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final bool isStriker;
  final String? dismissalType;

  const BatterState({
    required this.playerId,
    required this.playerName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.isOut,
    required this.isStriker,
    this.dismissalType,
  });

  double get strikeRate => balls > 0 ? (runs / balls) * 100 : 0;

  BatterState copyWith({
    String? playerId,
    String? playerName,
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    bool? isOut,
    bool? isStriker,
    String? dismissalType,
  }) {
    return BatterState(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOut: isOut ?? this.isOut,
      isStriker: isStriker ?? this.isStriker,
      dismissalType: dismissalType ?? this.dismissalType,
    );
  }

  factory BatterState.fromJson(Map<String, dynamic> json) => BatterState(
    playerId:     json['playerId'] ?? '',
    playerName:   json['playerName'] ?? '',
    runs:         json['runs'] ?? 0,
    balls:        json['balls'] ?? 0,
    fours:        json['fours'] ?? 0,
    sixes:        json['sixes'] ?? 0,
    isOut:        json['isOut'] ?? false,
    isStriker:    json['isStriker'] ?? false,
    dismissalType:json['dismissalType'],
  );

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'runs': runs,
    'balls': balls,
    'fours': fours,
    'sixes': sixes,
    'isOut': isOut,
    'isStriker': isStriker,
    if (dismissalType != null) 'dismissalType': dismissalType,
  };
}

class BowlerState {
  final String playerId;
  final String playerName;
  final int overs;
  final int balls;
  final int maidens;
  final int runs;
  final int wickets;
  final int wides;
  final int noBalls;
  final bool isCurrent;

  const BowlerState({
    required this.playerId,
    required this.playerName,
    required this.overs,
    required this.balls,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.wides,
    required this.noBalls,
    required this.isCurrent,
  });

  String get oversDisplay => '$overs.$balls';
  double get economy {
    final b = overs * 6 + balls;
    return b > 0 ? runs / (b / 6) : 0;
  }

  BowlerState copyWith({
    String? playerId,
    String? playerName,
    int? overs,
    int? balls,
    int? maidens,
    int? runs,
    int? wickets,
    int? wides,
    int? noBalls,
    bool? isCurrent,
  }) {
    return BowlerState(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      overs: overs ?? this.overs,
      balls: balls ?? this.balls,
      maidens: maidens ?? this.maidens,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  factory BowlerState.fromJson(Map<String, dynamic> json) => BowlerState(
    playerId:  json['playerId'] ?? '',
    playerName:json['playerName'] ?? '',
    overs:     json['overs'] ?? 0,
    balls:     json['balls'] ?? 0,
    maidens:   json['maidens'] ?? 0,
    runs:      json['runs'] ?? 0,
    wickets:   json['wickets'] ?? 0,
    wides:     json['wides'] ?? 0,
    noBalls:   json['noBalls'] ?? 0,
    isCurrent: json['isCurrent'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'overs': overs,
    'balls': balls,
    'maidens': maidens,
    'runs': runs,
    'wickets': wickets,
    'wides': wides,
    'noBalls': noBalls,
    'isCurrent': isCurrent,
  };
}

class ExtrasBreakdown {
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final int penalty;
  final int total;

  const ExtrasBreakdown({
    required this.wides,
    required this.noBalls,
    required this.byes,
    required this.legByes,
    required this.penalty,
    required this.total,
  });

  ExtrasBreakdown copyWith({
    int? wides,
    int? noBalls,
    int? byes,
    int? legByes,
    int? penalty,
    int? total,
  }) {
    return ExtrasBreakdown(
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      byes: byes ?? this.byes,
      legByes: legByes ?? this.legByes,
      penalty: penalty ?? this.penalty,
      total: total ?? this.total,
    );
  }

  factory ExtrasBreakdown.fromJson(Map<String, dynamic> json) => ExtrasBreakdown(
    wides:   json['wides']   ?? 0,
    noBalls: json['noBalls'] ?? 0,
    byes:    json['byes']    ?? 0,
    legByes: json['legByes'] ?? 0,
    penalty: json['penalty'] ?? 0,
    total:   json['total']   ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'wides': wides,
    'noBalls': noBalls,
    'byes': byes,
    'legByes': legByes,
    'penalty': penalty,
    'total': total,
  };
}

class FallOfWicket {
  final int wicketNumber;
  final int score;
  final String playerName;
  final int overNumber;
  final int ballNumber;

  const FallOfWicket({
    required this.wicketNumber,
    required this.score,
    required this.playerName,
    required this.overNumber,
    required this.ballNumber,
  });

  String get overDisplay => '$overNumber.$ballNumber';

  factory FallOfWicket.fromJson(Map<String, dynamic> json) => FallOfWicket(
    wicketNumber: json['wicketNumber'] ?? 0,
    score:        json['score']        ?? 0,
    playerName:   json['playerName']   ?? '',
    overNumber:   json['overNumber']   ?? 0,
    ballNumber:   json['ballNumber']   ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'wicketNumber': wicketNumber,
    'score': score,
    'playerName': playerName,
    'overNumber': overNumber,
    'ballNumber': ballNumber,
  };
}
