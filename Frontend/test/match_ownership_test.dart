import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricyy/models/match_model.dart';
import 'package:cricyy/providers/match_provider.dart';

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
}
