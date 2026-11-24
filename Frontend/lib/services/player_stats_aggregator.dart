// lib/services/player_stats_aggregator.dart

import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/innings_model.dart';

class PlayerMatchPerformance {
  final String matchId;
  final DateTime matchDate;
  final String format;
  final String teamName;
  final String opponentTeam;
  final int battingRuns;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final bool didBat;
  final bool isNotOut;
  final String? dismissalType;
  final double oversBowled;
  final int wicketsTaken;
  final int runsConceded;
  final int maidens;
  final bool didBowl;
  final double economy;

  const PlayerMatchPerformance({
    required this.matchId,
    required this.matchDate,
    required this.format,
    required this.teamName,
    required this.opponentTeam,
    required this.battingRuns,
    required this.ballsFaced,
    required this.fours,
    required this.sixes,
    required this.didBat,
    required this.isNotOut,
    this.dismissalType,
    required this.oversBowled,
    required this.wicketsTaken,
    required this.runsConceded,
    required this.maidens,
    required this.didBowl,
    required this.economy,
  });
}

class PlayerAggregatedProfile {
  final PlayerModel player;
  final BattingStats battingStats;
  final BowlingStats bowlingStats;
  final List<PlayerMatchPerformance> matchPerformances;

  const PlayerAggregatedProfile({
    required this.player,
    required this.battingStats,
    required this.bowlingStats,
    required this.matchPerformances,
  });
}

class PlayerStatsAggregator {
  PlayerStatsAggregator._();

  static List<PlayerAggregatedProfile> aggregateFromMatches(List<MatchModel> matches) {
    final Map<String, _PlayerCollector> collectors = {};

    for (final match in matches) {
      final inningsList = <InningsModel>[];
      if (match.innings1 != null) inningsList.add(match.innings1!);
      if (match.innings2 != null) inningsList.add(match.innings2!);

      for (final inn in inningsList) {
        // Collect Batters
        final seenBatters = <String>{};
        for (final b in inn.battersUsed) {
          final key = b.playerName.trim().toLowerCase();
          if (key.isEmpty) continue;
          seenBatters.add(key);

          final collector = collectors.putIfAbsent(
            key,
            () => _PlayerCollector(rawName: b.playerName.trim()),
          );

          collector.recordBatting(
            match: match,
            innings: inn,
            batter: b,
          );
        }
        for (final b in inn.currentBatters) {
          final key = b.playerName.trim().toLowerCase();
          if (key.isEmpty || seenBatters.contains(key)) continue;

          final collector = collectors.putIfAbsent(
            key,
            () => _PlayerCollector(rawName: b.playerName.trim()),
          );

          collector.recordBatting(
            match: match,
            innings: inn,
            batter: b,
          );
        }

        // Collect Bowlers
        for (final b in inn.bowlersUsed) {
          final key = b.playerName.trim().toLowerCase();
          if (key.isEmpty) continue;

          final collector = collectors.putIfAbsent(
            key,
            () => _PlayerCollector(rawName: b.playerName.trim()),
          );

          collector.recordBowling(
            match: match,
            innings: inn,
            bowler: b,
          );
        }
      }
    }

    final profiles = collectors.values.map((c) => c.buildProfile()).toList();
    // Sort players by total runs desc, then total wickets desc
    profiles.sort((a, b) {
      final runComp = b.battingStats.totalRuns.compareTo(a.battingStats.totalRuns);
      if (runComp != 0) return runComp;
      return b.bowlingStats.totalWickets.compareTo(a.bowlingStats.totalWickets);
    });

    return profiles;
  }
}

class _PlayerCollector {
  final String rawName;
  final Map<String, _MatchPerformer> matchMap = {};

  _PlayerCollector({required this.rawName});

  void recordBatting({
    required MatchModel match,
    required InningsModel innings,
    required BatterState batter,
  }) {
    final p = matchMap.putIfAbsent(
      match.id,
      () => _MatchPerformer(
        matchId: match.id,
        matchDate: match.matchDate,
        format: match.format,
        teamName: innings.battingTeamName,
        opponentTeam: innings.bowlingTeamName,
      ),
    );

    p.didBat = true;
    p.battingRuns += batter.runs;
    p.ballsFaced += batter.balls;
    p.fours += batter.fours;
    p.sixes += batter.sixes;
    p.isNotOut = !batter.isOut;
    p.dismissalType = batter.dismissalType;
  }

  void recordBowling({
    required MatchModel match,
    required InningsModel innings,
    required BowlerState bowler,
  }) {
    final p = matchMap.putIfAbsent(
      match.id,
      () => _MatchPerformer(
        matchId: match.id,
        matchDate: match.matchDate,
        format: match.format,
        teamName: innings.bowlingTeamName,
        opponentTeam: innings.battingTeamName,
      ),
    );

    p.didBowl = true;
    p.overs += bowler.overs;
    p.balls += bowler.balls;
    p.maidens += bowler.maidens;
    p.runsConceded += bowler.runs;
    p.wickets += bowler.wickets;
    p.wides += bowler.wides;
    p.noBalls += bowler.noBalls;
  }

  PlayerAggregatedProfile buildProfile() {
    final performances = matchMap.values.map((m) => m.toPerformance()).toList()
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

    // Batting Calculations
    int battingInnings = 0;
    int totalRuns = 0;
    int totalBalls = 0;
    int totalFours = 0;
    int totalSixes = 0;
    int notOuts = 0;
    int highestScore = 0;
    int halfCenturies = 0;
    int centuries = 0;
    int dismissals = 0;

    for (final p in performances) {
      if (p.didBat) {
        battingInnings++;
        totalRuns += p.battingRuns;
        totalBalls += p.ballsFaced;
        totalFours += p.fours;
        totalSixes += p.sixes;
        if (p.battingRuns > highestScore) {
          highestScore = p.battingRuns;
        }
        if (p.isNotOut) {
          notOuts++;
        } else {
          dismissals++;
        }
        if (p.battingRuns >= 100) {
          centuries++;
        } else if (p.battingRuns >= 50) {
          halfCenturies++;
        }
      }
    }

    final double? battingAverage = dismissals > 0
        ? double.parse((totalRuns / dismissals).toStringAsFixed(2))
        : (battingInnings > 0 ? null : 0.0);

    final double strikeRate = totalBalls > 0
        ? double.parse(((totalRuns / totalBalls) * 100).toStringAsFixed(1))
        : 0.0;

    final battingStats = BattingStats(
      totalMatches: performances.length,
      battingInnings: battingInnings,
      totalRuns: totalRuns,
      highestScore: highestScore,
      notOuts: notOuts,
      battingAverage: battingAverage,
      strikeRate: strikeRate,
      totalBalls: totalBalls,
      totalFours: totalFours,
      totalSixes: totalSixes,
      halfCenturies: halfCenturies,
      centuries: centuries,
    );

    // Bowling Calculations
    int bowlingInnings = 0;
    int totalLegalBalls = 0;
    int maidens = 0;
    int runsConceded = 0;
    int wickets = 0;
    int threeWkts = 0;
    int fourWkts = 0;
    int fiveWkts = 0;
    String? bestBowling;
    int bestWkts = -1;
    int bestRuns = 9999;

    for (final p in performances) {
      if (p.didBowl) {
        bowlingInnings++;
        final fullOvers = p.oversBowled.truncate();
        final remBalls = ((p.oversBowled - fullOvers) * 10).round();
        totalLegalBalls += fullOvers * 6 + remBalls;
        maidens += p.maidens;
        runsConceded += p.runsConceded;
        wickets += p.wicketsTaken;

        if (p.wicketsTaken >= 5) {
          fiveWkts++;
        } else if (p.wicketsTaken == 4) {
          fourWkts++;
        } else if (p.wicketsTaken >= 3) {
          threeWkts++;
        }

        if (p.wicketsTaken > bestWkts || (p.wicketsTaken == bestWkts && p.runsConceded < bestRuns)) {
          bestWkts = p.wicketsTaken;
          bestRuns = p.runsConceded;
          bestBowling = '$bestWkts/$bestRuns';
        }
      }
    }

    final int completedOvers = totalLegalBalls ~/ 6;
    final int extraBalls = totalLegalBalls % 6;
    final double formattedOvers = completedOvers + (extraBalls / 10.0);

    final double? bowlingAverage = wickets > 0
        ? double.parse((runsConceded / wickets).toStringAsFixed(2))
        : null;

    final double economyRate = totalLegalBalls > 0
        ? double.parse((runsConceded / (totalLegalBalls / 6.0)).toStringAsFixed(2))
        : 0.0;

    final double? bowlingStrikeRate = wickets > 0
        ? double.parse((totalLegalBalls / wickets).toStringAsFixed(1))
        : null;

    final bowlingStats = BowlingStats(
      bowlingMatches: performances.where((p) => p.didBowl).length,
      bowlingInnings: bowlingInnings,
      totalLegalBalls: totalLegalBalls,
      overs: formattedOvers,
      maidens: maidens,
      totalRunsConceded: runsConceded,
      totalWickets: wickets,
      bowlingAverage: bowlingAverage,
      economyRate: economyRate,
      bowlingStrikeRate: bowlingStrikeRate,
      bestBowling: bestBowling,
      threeWicketHauls: threeWkts,
      fourWicketHauls: fourWkts,
      fiveWicketHauls: fiveWkts,
    );

    return PlayerAggregatedProfile(
      player: PlayerModel(
        id: rawName.toLowerCase().replaceAll(' ', '_'),
        name: rawName,
      ),
      battingStats: battingStats,
      bowlingStats: bowlingStats,
      matchPerformances: performances,
    );
  }
}

class _MatchPerformer {
  final String matchId;
  final DateTime matchDate;
  final String format;
  final String teamName;
  final String opponentTeam;

  bool didBat = false;
  int battingRuns = 0;
  int ballsFaced = 0;
  int fours = 0;
  int sixes = 0;
  bool isNotOut = true;
  String? dismissalType;

  bool didBowl = false;
  int overs = 0;
  int balls = 0;
  int maidens = 0;
  int runsConceded = 0;
  int wickets = 0;
  int wides = 0;
  int noBalls = 0;

  _MatchPerformer({
    required this.matchId,
    required this.matchDate,
    required this.format,
    required this.teamName,
    required this.opponentTeam,
  });

  PlayerMatchPerformance toPerformance() {
    final double oversDec = overs + (balls / 10.0);
    final totalBalls = overs * 6 + balls;
    final double eco = totalBalls > 0 ? (runsConceded / (totalBalls / 6.0)) : 0.0;

    return PlayerMatchPerformance(
      matchId: matchId,
      matchDate: matchDate,
      format: format,
      teamName: teamName,
      opponentTeam: opponentTeam,
      battingRuns: battingRuns,
      ballsFaced: ballsFaced,
      fours: fours,
      sixes: sixes,
      didBat: didBat,
      isNotOut: isNotOut,
      dismissalType: dismissalType,
      oversBowled: oversDec,
      wicketsTaken: wickets,
      runsConceded: runsConceded,
      maidens: maidens,
      didBowl: didBowl,
      economy: double.parse(eco.toStringAsFixed(1)),
    );
  }
}
