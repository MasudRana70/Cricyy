import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
