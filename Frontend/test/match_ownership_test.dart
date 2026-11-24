import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricyy/models/innings_model.dart';
import 'package:cricyy/models/match_model.dart';
import 'package:cricyy/providers/match_provider.dart';
import 'package:cricyy/services/match_api_service.dart';

class _FakeMatchApiService extends MatchApiService {
  List<MatchModel> remoteMatches;
  int upsertCount = 0;

  _FakeMatchApiService(this.remoteMatches);

  @override
  Future<List<MatchModel>> fetchSharedMatches({String? status, int limit = 100}) async {
    return List<MatchModel>.from(remoteMatches);
  }

  @override
  Future<MatchModel> upsertSharedMatch(MatchModel match, {String? deviceId}) async {
    upsertCount++;
    return match;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Match creator can delete their own match, non-creators cannot', () async {
    final prov = MatchProvider(enableAutoRefresh: false);
    await prov.loadMatches();

    prov.createNewMatch(
      team1Name: 'Alpha',
      team2Name: 'Beta',
      format: 'T10',
      totalOvers: 10,
      playersPerSide: 11,
      tossWinner: 'Alpha',
      tossDecision: 'bat',
      strikerName: 'Player 1',
      nonStrikerName: 'Player 2',
      openingBowlerName: 'Bowler 1',
    );

    final created = prov.selectedMatch!;
    expect(created.creatorId, isNotNull);
    expect(created.creatorId, equals(prov.deviceId));
    expect(prov.canDeleteMatch(created), isTrue);

    // Match created by a different device/user cannot be deleted
    final otherUsersMatch = MatchModel(
      id: 'match_other_user',
      creatorId: 'dev_someone_else',
      team1Id: 't1',
      team2Id: 't2',
      team1Name: 'Gamma',
      team2Name: 'Delta',
      format: 'T20',
      totalOvers: 20,
      status: 'in_progress',
      matchDate: DateTime.now(),
      rules: const MatchRules(
        ruleset: 'MCC_2026',
        maxOversPerBowler: 0,
        playersPerSide: 11,
        overLength: 6,
      ),
    );
    expect(prov.canDeleteMatch(otherUsersMatch), isFalse);

    // Legacy match with null creatorId cannot be deleted by random device
    final legacyMatch = otherUsersMatch.copyWith(id: 'match_legacy');
    expect(prov.canDeleteMatch(MatchModel(
      id: legacyMatch.id,
      creatorId: null,
      team1Id: 't1',
      team2Id: 't2',
      team1Name: 'Gamma',
      team2Name: 'Delta',
      format: 'T20',
      totalOvers: 20,
      status: 'in_progress',
      matchDate: DateTime.now(),
      rules: legacyMatch.rules,
    )), isFalse);

    // Deleting own match succeeds
    final deletedOwn = await prov.deleteMatch(created.id);
    expect(deletedOwn, isTrue);
    expect(prov.matches, isEmpty);
  });

  test('Matches deleted from database/server are removed locally and not re-uploaded', () async {
    final legacyCachedMatch = MatchModel(
      id: 'match_old_server',
      creatorId: null,
      team1Id: 't1',
      team2Id: 't2',
      team1Name: 'Old A',
      team2Name: 'Old B',
      format: 'T10',
      totalOvers: 10,
      status: 'in_progress',
      matchDate: DateTime.now(),
      rules: const MatchRules(
        ruleset: 'MCC_2026',
        maxOversPerBowler: 0,
        playersPerSide: 11,
        overLength: 6,
      ),
    );
    SharedPreferences.setMockInitialValues({
      'cricyy_saved_matches': jsonEncode([legacyCachedMatch.toJson()]),
    });

    final fakeApi = _FakeMatchApiService([]);
    final prov = MatchProvider(apiService: fakeApi, enableAutoRefresh: false);
    await prov.loadMatches();
    expect(prov.matches, hasLength(1));

    // When server no longer returns match_old_server, refresh removes it without re-uploading
    await prov.refreshMatches(silent: true);
    expect(fakeApi.upsertCount, 0);
    expect(prov.matches, isEmpty);
  });

  test('Non-creator cannot score, swap strike, change bowler, or start 2nd innings', () async {
    final otherInnings = InningsModel(
      id: 'inn_other_1',
      matchId: 'match_other_live',
      inningsNumber: 1,
      battingTeamId: 't1',
      battingTeamName: 'Team A',
      bowlingTeamId: 't2',
      bowlingTeamName: 'Team B',
      totalRuns: 10,
      totalWickets: 0,
      completedOvers: 1,
      currentBallInOver: 0,
      totalLegalBalls: 6,
      extras: const ExtrasBreakdown(wides: 0, noBalls: 0, byes: 0, legByes: 0, penalty: 0, total: 0),
      status: 'in_progress',
      currentBatters: const [
        BatterState(playerId: 'b1', playerName: 'Ali', runs: 6, balls: 3, fours: 1, sixes: 0, isOut: false, isStriker: true),
        BatterState(playerId: 'b2', playerName: 'Sara', runs: 4, balls: 3, fours: 1, sixes: 0, isOut: false, isStriker: false),
      ],
      battersUsed: const [
        BatterState(playerId: 'b1', playerName: 'Ali', runs: 6, balls: 3, fours: 1, sixes: 0, isOut: false, isStriker: true),
        BatterState(playerId: 'b2', playerName: 'Sara', runs: 4, balls: 3, fours: 1, sixes: 0, isOut: false, isStriker: false),
      ],
      bowlersUsed: const [
        BowlerState(playerId: 'bw1', playerName: 'Zain', overs: 1, balls: 0, maidens: 0, runs: 10, wickets: 0, wides: 0, noBalls: 0, isCurrent: true),
      ],
      fallOfWickets: const [],
    );

    final otherLiveMatch = MatchModel(
      id: 'match_other_live',
      creatorId: 'dev_someone_else',
      team1Id: 't1',
      team2Id: 't2',
      team1Name: 'Team A',
      team2Name: 'Team B',
      format: 'T10',
      totalOvers: 10,
      status: 'in_progress',
      matchDate: DateTime.now(),
      rules: const MatchRules(
        ruleset: 'MCC_2026',
        maxOversPerBowler: 0,
        playersPerSide: 11,
        overLength: 6,
      ),
      innings1: otherInnings,
    );

    SharedPreferences.setMockInitialValues({
      'cricyy_saved_matches': jsonEncode([otherLiveMatch.toJson()]),
    });

    final prov = MatchProvider(enableAutoRefresh: false);
    await prov.loadMatches();

    expect(prov.selectedMatch?.id, 'match_other_live');
    expect(prov.canEditMatch(prov.selectedMatch), isFalse);
    expect(prov.canDeleteMatch(prov.selectedMatch), isFalse);

    prov.recordBall(runs: 6, extraType: 'none');
    prov.swapStrike();
    prov.setNextBowler('Unauthorized Bowler');
    prov.startSecondInnings(strikerName: 'X', nonStrikerName: 'Y', openingBowlerName: 'Z');
    prov.undoBall();

    expect(prov.currentInnings?.totalRuns, 10);
    expect(prov.currentInnings?.striker?.playerName, 'Ali');
    expect(prov.currentInnings?.currentBowler?.playerName, 'Zain');
    expect(prov.secondInnings, isNull);
  });
}
