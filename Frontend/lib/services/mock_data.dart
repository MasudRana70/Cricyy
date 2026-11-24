// lib/services/mock_data.dart
// All mock data for UI development — replace with real API calls in Phase 8.

import '../models/player_model.dart';
import '../models/match_model.dart';
import '../models/innings_model.dart';

class MockData {
  MockData._();

  // ── Players ───────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> players = [
    {'_id': 'p1', 'name': 'Shakib Al Hasan',   'shortName': 'Shakib'},
    {'_id': 'p2', 'name': 'Tamim Iqbal',        'shortName': 'Tamim'},
    {'_id': 'p3', 'name': 'Mushfiqur Rahim',    'shortName': 'Mushfiq'},
    {'_id': 'p4', 'name': 'Mahmudullah Riyad',  'shortName': 'Mahmud'},
    {'_id': 'p5', 'name': 'Mustafizur Rahman',  'shortName': 'Mustafiz'},
    {'_id': 'p6', 'name': 'Liton Das',          'shortName': 'Liton'},
    {'_id': 'p7', 'name': 'Mehidy Hasan Miraz', 'shortName': 'Miraz'},
    {'_id': 'p8', 'name': 'Taskin Ahmed',       'shortName': 'Taskin'},
    {'_id': 'p9', 'name': 'Nazmul Hossain Shanto', 'shortName': 'Shanto'},
    {'_id': 'p10','name': 'Towhid Hridoy',      'shortName': 'Hridoy'},
    {'_id': 'p11','name': 'Hasan Mahmud',       'shortName': 'Hasan'},
    {'_id': 'p12','name': 'Rony Talukdar',      'shortName': 'Rony'},
    {'_id': 'p13','name': 'Jaker Ali',          'shortName': 'Jaker'},
    {'_id': 'p14','name': 'Shoriful Islam',     'shortName': 'Shoriful'},
    {'_id': 'p15','name': 'Tanzim Hasan Sakib', 'shortName': 'Tanzim'},
  ];

  static List<PlayerModel> get playerList =>
      players.map((p) => PlayerModel.fromJson(p)).toList();

  // ── Teams ─────────────────────────────────────────────────────────────────
  static final TeamModel teamA = TeamModel.fromJson({
    '_id': 't1', 'name': 'Tigers CC', 'shortName': 'TIG',
    'members': players.sublist(0, 11).map((p) => {'_id': p['_id'], 'name': p['name'], 'shortName': p['shortName']}).toList(),
  });

  static final TeamModel teamB = TeamModel.fromJson({
    '_id': 't2', 'name': 'Lions CC', 'shortName': 'LIO',
    'members': players.sublist(4, 15).map((p) => {'_id': p['_id'], 'name': p['name'], 'shortName': p['shortName']}).toList(),
  });

  // ── Live Match ────────────────────────────────────────────────────────────
  static MatchModel get liveMatch => MatchModel.fromJson({
    '_id': 'm1',
    'team1Id': 't1', 'team1Name': 'Tigers CC',
    'team2Id': 't2', 'team2Name': 'Lions CC',
    'format': 'T20', 'totalOvers': 20,
    'status': 'in_progress',
    'matchDate': DateTime.now().toIso8601String(),
    'venue': 'Sher-e-Bangla National Stadium',
    'toss': {'winnerTeamId': 't1', 'decision': 'bat'},
    'rules': {'ruleset': 'MCC_2026', 'maxOversPerBowler': 4, 'playersPerSide': 11, 'overLength': 6},
  });

  static MatchModel get completedMatch1 => MatchModel.fromJson({
    '_id': 'm2',
    'team1Id': 't1', 'team1Name': 'Tigers CC',
    'team2Id': 't2', 'team2Name': 'Lions CC',
    'format': 'T20', 'totalOvers': 20,
    'status': 'completed',
    'matchDate': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    'result': {'type': 'win_by_runs', 'winnerTeamId': 't1', 'marginRuns': 23, 'description': 'Tigers CC won by 23 runs'},
    'toss': {'winnerTeamId': 't2', 'decision': 'bowl'},
    'rules': {'ruleset': 'MCC_2026', 'maxOversPerBowler': 4, 'playersPerSide': 11, 'overLength': 6},
  });

  static MatchModel get completedMatch2 => MatchModel.fromJson({
    '_id': 'm3',
    'team1Id': 't1', 'team1Name': 'Tigers CC',
    'team2Id': 't2', 'team2Name': 'Lions CC',
    'format': 'ODI', 'totalOvers': 50,
    'status': 'completed',
    'matchDate': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
    'result': {'type': 'win_by_wickets', 'winnerTeamId': 't2', 'marginWickets': 4, 'description': 'Lions CC won by 4 wickets'},
    'rules': {'ruleset': 'MCC_2026', 'maxOversPerBowler': 10, 'playersPerSide': 11, 'overLength': 6},
  });

  static List<MatchModel> get matchHistory => [liveMatch, completedMatch1, completedMatch2];

  // ── Live Innings ──────────────────────────────────────────────────────────
  static InningsModel get liveInnings => InningsModel.fromJson({
    '_id': 'inn1', 'matchId': 'm1',
    'inningsNumber': 1,
    'battingTeamId': 't1', 'battingTeamName': 'Tigers CC',
    'bowlingTeamId': 't2', 'bowlingTeamName': 'Lions CC',
    'totalRuns': 142, 'totalWickets': 4,
    'completedOvers': 16, 'currentBallInOver': 3,
    'totalLegalBalls': 99,
    'target': null,
    'status': 'in_progress',
    'extras': {'wides': 4, 'noBalls': 2, 'byes': 1, 'legByes': 3, 'penalty': 0, 'total': 10},
    'currentBatters': [
      {'playerId': 'p4', 'playerName': 'Mahmudullah', 'runs': 38, 'balls': 29, 'fours': 4, 'sixes': 1, 'isOut': false, 'isStriker': true},
      {'playerId': 'p6', 'playerName': 'Liton Das',   'runs': 22, 'balls': 18, 'fours': 2, 'sixes': 0, 'isOut': false, 'isStriker': false},
    ],
    'battersUsed': [
      {'playerId': 'p2', 'playerName': 'Tamim Iqbal',    'runs': 45, 'balls': 38, 'fours': 6, 'sixes': 1, 'isOut': true,  'isStriker': false},
      {'playerId': 'p9', 'playerName': 'Shanto',          'runs': 12, 'balls': 15, 'fours': 1, 'sixes': 0, 'isOut': true,  'isStriker': false},
      {'playerId': 'p1', 'playerName': 'Shakib',          'runs': 25, 'balls': 20, 'fours': 3, 'sixes': 0, 'isOut': true,  'isStriker': false},
      {'playerId': 'p3', 'playerName': 'Mushfiqur',       'runs': 0,  'balls': 4,  'fours': 0, 'sixes': 0, 'isOut': true,  'isStriker': false},
      {'playerId': 'p4', 'playerName': 'Mahmudullah',     'runs': 38, 'balls': 29, 'fours': 4, 'sixes': 1, 'isOut': false, 'isStriker': true},
      {'playerId': 'p6', 'playerName': 'Liton Das',       'runs': 22, 'balls': 18, 'fours': 2, 'sixes': 0, 'isOut': false, 'isStriker': false},
    ],
    'bowlersUsed': [
      {'playerId': 'p5',  'playerName': 'Mustafiz',  'overs': 4, 'balls': 0, 'maidens': 1, 'runs': 28, 'wickets': 2, 'wides': 2, 'noBalls': 0, 'isCurrent': false},
      {'playerId': 'p7',  'playerName': 'Miraz',     'overs': 4, 'balls': 0, 'maidens': 0, 'runs': 32, 'wickets': 1, 'wides': 0, 'noBalls': 1, 'isCurrent': false},
      {'playerId': 'p8',  'playerName': 'Taskin',    'overs': 4, 'balls': 0, 'maidens': 0, 'runs': 38, 'wickets': 1, 'wides': 1, 'noBalls': 1, 'isCurrent': false},
      {'playerId': 'p11', 'playerName': 'Hasan',     'overs': 3, 'balls': 3, 'maidens': 0, 'runs': 34, 'wickets': 0, 'wides': 1, 'noBalls': 0, 'isCurrent': true},
    ],
    'fallOfWickets': [
      {'wicketNumber': 1, 'score': 42,  'playerName': 'Tamim Iqbal', 'overNumber': 7,  'ballNumber': 2},
      {'wicketNumber': 2, 'score': 60,  'playerName': 'Shanto',      'overNumber': 10, 'ballNumber': 4},
      {'wicketNumber': 3, 'score': 112, 'playerName': 'Shakib',      'overNumber': 14, 'ballNumber': 1},
      {'wicketNumber': 4, 'score': 115, 'playerName': 'Mushfiqur',   'overNumber': 14, 'ballNumber': 5},
    ],
  });

  // ── Player Career Stats ───────────────────────────────────────────────────
  static BattingStats get shakibBatting => BattingStats.fromJson({
    'totalMatches': 42, 'battingInnings': 40, 'totalRuns': 1245,
    'highestScore': 97, 'notOuts': 5, 'battingAverage': 35.57,
    'strikeRate': 128.4, 'totalBalls': 969, 'totalFours': 108,
    'totalSixes': 32, 'halfCenturies': 8, 'centuries': 0,
  });

  static BowlingStats get shakibBowling => BowlingStats.fromJson({
    'bowlingMatches': 42, 'bowlingInnings': 40, 'totalLegalBalls': 1440,
    'overs': 240.0, 'maidens': 12, 'totalRunsConceded': 1680,
    'totalWickets': 68, 'bowlingAverage': 24.71, 'economyRate': 7.0,
    'bowlingStrikeRate': 21.2, 'bestBowling': '5/22',
    'threeWicketHauls': 6, 'fourWicketHauls': 2, 'fiveWicketHauls': 1,
  });

  static List<Map<String, dynamic>> get shakibMatchHistory => [
    {'matchDate': '2026-11-10', 'opponent': 'Lions CC', 'format': 'T20',
     'batting': {'runs': 67, 'balls': 48, 'fours': 6, 'sixes': 2, 'isNotOut': false, 'dismissalType': 'caught'},
     'bowling': {'overs': 4.0, 'wickets': 2, 'runs': 28, 'economy': 7.0}},
    {'matchDate': '2026-11-05', 'opponent': 'Lions CC', 'format': 'T20',
     'batting': {'runs': 23, 'balls': 19, 'fours': 2, 'sixes': 1, 'isNotOut': false, 'dismissalType': 'bowled'},
     'bowling': {'overs': 4.0, 'wickets': 1, 'runs': 32, 'economy': 8.0}},
    {'matchDate': '2026-10-28', 'opponent': 'Lions CC', 'format': 'ODI',
     'batting': {'runs': 97, 'balls': 86, 'fours': 9, 'sixes': 2, 'isNotOut': false, 'dismissalType': 'run_out'},
     'bowling': {'overs': 10.0, 'wickets': 3, 'runs': 55, 'economy': 5.5}},
    {'matchDate': '2026-10-15', 'opponent': 'Lions CC', 'format': 'T10',
     'batting': {'runs': 34, 'balls': 22, 'fours': 4, 'sixes': 1, 'isNotOut': true,  'dismissalType': null},
     'bowling': {'overs': 2.0, 'wickets': 1, 'runs': 18, 'economy': 9.0}},
  ];
}
