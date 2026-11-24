// lib/models/match_model.dart

import 'innings_model.dart';

class TeamModel {
  final String id;
  final String name;
  final String? shortName;
  final List<PlayerRef> members;

  const TeamModel({
    required this.id,
    required this.name,
    this.shortName,
    this.members = const [],
  });

  String get displayName => shortName ?? name;

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    shortName: json['shortName'],
    members: (json['members'] as List<dynamic>? ?? [])
        .map((m) => PlayerRef.fromJson(m as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    if (shortName != null) 'shortName': shortName,
    'members': members.map((m) => m.toJson()).toList(),
  };
}

class PlayerRef {
  final String id;
  final String name;
  final String? shortName;
  const PlayerRef({required this.id, required this.name, this.shortName});

  factory PlayerRef.fromJson(Map<String, dynamic> json) => PlayerRef(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    shortName: json['shortName'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    if (shortName != null) 'shortName': shortName,
  };

  String get displayName => shortName ?? name;
}

// ── Match ─────────────────────────────────────────────────────────────────────
class MatchModel {
  final String id;
  final String? creatorId;
  final String team1Id;
  final String team2Id;
  final String team1Name;
  final String team2Name;
  final String format;
  final int totalOvers;
  final String status;
  final DateTime matchDate;
  final String? venue;
  final MatchResult? result;
  final TossInfo? toss;
  final MatchRules rules;
  final InningsModel? innings1;
  final InningsModel? innings2;
  final DateTime? updatedAt;
  final int syncVersion;

  const MatchModel({
    required this.id,
    this.creatorId,
    required this.team1Id,
    required this.team2Id,
    required this.team1Name,
    required this.team2Name,
    required this.format,
    required this.totalOvers,
    required this.status,
    required this.matchDate,
    this.venue,
    this.result,
    this.toss,
    required this.rules,
    this.innings1,
    this.innings2,
    this.updatedAt,
    this.syncVersion = 1,
  });

  bool get isLive => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  MatchModel copyWith({
    String? id,
    String? creatorId,
    String? team1Id,
    String? team2Id,
    String? team1Name,
    String? team2Name,
    String? format,
    int? totalOvers,
    String? status,
    DateTime? matchDate,
    String? venue,
    MatchResult? result,
    TossInfo? toss,
    MatchRules? rules,
    InningsModel? innings1,
    InningsModel? innings2,
    DateTime? updatedAt,
    int? syncVersion,
  }) {
    return MatchModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      format: format ?? this.format,
      totalOvers: totalOvers ?? this.totalOvers,
      status: status ?? this.status,
      matchDate: matchDate ?? this.matchDate,
      venue: venue ?? this.venue,
      result: result ?? this.result,
      toss: toss ?? this.toss,
      rules: rules ?? this.rules,
      innings1: innings1 ?? this.innings1,
      innings2: innings2 ?? this.innings2,
      updatedAt: updatedAt ?? this.updatedAt,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
    id:          json['_id'] ?? json['id'] ?? '',
    creatorId:   json['creatorId']?.toString(),
    team1Id:     json['team1Id'] ?? '',
    team2Id:     json['team2Id'] ?? '',
    team1Name:   json['team1Name'] ?? '',
    team2Name:   json['team2Name'] ?? '',
    format:      json['format'] ?? '',
    totalOvers:  json['totalOvers'] ?? 20,
    status:      json['status'] ?? 'setup',
    matchDate:   DateTime.tryParse(json['matchDate']?.toString() ?? '') ?? DateTime.now(),
    venue:       json['venue'],
    result:      json['result'] != null ? MatchResult.fromJson(Map<String, dynamic>.from(json['result'])) : null,
    toss:        json['toss']   != null ? TossInfo.fromJson(Map<String, dynamic>.from(json['toss']))     : null,
    rules:       MatchRules.fromJson(json['rules'] != null ? Map<String, dynamic>.from(json['rules']) : {}),
    innings1:    json['innings1'] != null ? InningsModel.fromJson(Map<String, dynamic>.from(json['innings1'])) : null,
    innings2:    json['innings2'] != null ? InningsModel.fromJson(Map<String, dynamic>.from(json['innings2'])) : null,
    updatedAt:   json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    syncVersion: json['syncVersion'] ?? 1,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    if (creatorId != null) 'creatorId': creatorId,
    'team1Id': team1Id,
    'team2Id': team2Id,
    'team1Name': team1Name,
    'team2Name': team2Name,
    'format': format,
    'totalOvers': totalOvers,
    'status': status,
    'matchDate': matchDate.toIso8601String(),
    if (venue != null) 'venue': venue,
    if (result != null) 'result': result!.toJson(),
    if (toss != null) 'toss': toss!.toJson(),
    'rules': rules.toJson(),
    if (innings1 != null) 'innings1': innings1!.toJson(),
    if (innings2 != null) 'innings2': innings2!.toJson(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'syncVersion': syncVersion,
  };
}

class MatchResult {
  final String type;
  final String? winnerTeamId;
  final int? marginRuns;
  final int? marginWickets;
  final String? description;

  const MatchResult({
    required this.type,
    this.winnerTeamId,
    this.marginRuns,
    this.marginWickets,
    this.description,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
    type:          json['type'] ?? '',
    winnerTeamId:  json['winnerTeamId'],
    marginRuns:    json['marginRuns'],
    marginWickets: json['marginWickets'],
    description:   json['description'],
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    if (winnerTeamId != null) 'winnerTeamId': winnerTeamId,
    if (marginRuns != null) 'marginRuns': marginRuns,
    if (marginWickets != null) 'marginWickets': marginWickets,
    if (description != null) 'description': description,
  };
}

class TossInfo {
  final String winnerTeamId;
  final String decision;
  const TossInfo({required this.winnerTeamId, required this.decision});

  factory TossInfo.fromJson(Map<String, dynamic> json) => TossInfo(
    winnerTeamId: json['winnerTeamId'] ?? '',
    decision:     json['decision'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'winnerTeamId': winnerTeamId,
    'decision': decision,
  };
}

class MatchRules {
  final String ruleset;
  final int maxOversPerBowler;
  final int playersPerSide;
  final int overLength;

  const MatchRules({
    required this.ruleset,
    required this.maxOversPerBowler,
    required this.playersPerSide,
    required this.overLength,
  });

  factory MatchRules.fromJson(Map<String, dynamic> json) => MatchRules(
    ruleset:            json['ruleset']            ?? 'MCC_2026',
    maxOversPerBowler:  json['maxOversPerBowler']  ?? 0,
    playersPerSide:     json['playersPerSide']     ?? 11,
    overLength:         json['overLength']         ?? 6,
  );

  Map<String, dynamic> toJson() => {
    'ruleset': ruleset,
    'maxOversPerBowler': maxOversPerBowler,
    'playersPerSide': playersPerSide,
    'overLength': overLength,
  };
}
