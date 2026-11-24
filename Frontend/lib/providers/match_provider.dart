// lib/providers/match_provider.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/app_constants.dart';
import '../models/match_model.dart';
import '../models/innings_model.dart';
import '../services/local_storage_service.dart';
import '../services/match_api_service.dart';

class BallResult {
  final bool overCompleted;
  final bool inningsCompleted;
  final bool matchCompleted;
  final bool isWicket;
  final String? message;

  const BallResult({
    this.overCompleted = false,
    this.inningsCompleted = false,
    this.matchCompleted = false,
    this.isWicket = false,
    this.message,
  });
}

class MatchProvider extends ChangeNotifier {
  static const Duration autoRefreshInterval = Duration(seconds: 5);

  final MatchApiService _apiService;
  final bool _allowBackgroundTimers;

  List<MatchModel> _matches = [];
  MatchModel? _selectedMatch;
  InningsModel? _currentInnings;
  InningsModel? _firstInnings;
  InningsModel? _secondInnings;
  final List<InningsModel> _undoStack = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isCloudConnected = false;
  bool _autoRefreshEnabled = true;
  bool _disposed = false;
  DateTime? _lastSyncedAt;
  String? _error;
  String? _syncError;

  Timer? _autoRefreshTimer;
  Set<String> _pendingSyncMatchIds = {};
  final Map<String, DateTime> _lastLocalMutationAt = {};
  final Map<String, MatchModel> _queuedSyncPayload = {};
  final Set<String> _activeSyncInFlight = {};

  MatchProvider({
    MatchApiService? apiService,
    bool? enableAutoRefresh,
  })  : _apiService = apiService ?? MatchApiService(),
        _allowBackgroundTimers = enableAutoRefresh ??
            !WidgetsBinding.instance.runtimeType.toString().contains('Test') {
    loadMatches();
    if (_allowBackgroundTimers && _autoRefreshEnabled) {
      startAutoRefresh();
    }
  }

  List<MatchModel> get matches          => _matches;
  MatchModel?       get selectedMatch    => _selectedMatch;
  InningsModel?     get currentInnings   => _currentInnings;
  InningsModel?     get firstInnings     => _firstInnings;
  InningsModel?     get secondInnings    => _secondInnings;
  bool              get canUndo          => _undoStack.isNotEmpty;
  bool              get isLoading        => _isLoading;
  bool              get isRefreshing     => _isRefreshing;
  bool              get isCloudConnected => _isCloudConnected;
  bool              get autoRefreshEnabled => _autoRefreshEnabled;
  DateTime?         get lastSyncedAt     => _lastSyncedAt;
  String?           get error            => _error;
  String?           get syncError        => _syncError;

  List<MatchModel> get liveMatches =>
      _matches.where((m) => m.isLive).toList();

  List<MatchModel> get completedMatches =>
      _matches.where((m) => m.isCompleted).toList();

  @override
  void dispose() {
    _disposed = true;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void startAutoRefresh() {
    if (!_allowBackgroundTimers || _disposed) return;
    _autoRefreshTimer?.cancel();
    _autoRefreshEnabled = true;
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (_) {
      if (_autoRefreshEnabled && !_isRefreshing && !_disposed) {
        refreshMatches(silent: true);
      }
    });
    _safeNotify();
  }

  void stopAutoRefresh() {
    _autoRefreshEnabled = false;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _safeNotify();
  }

  void toggleAutoRefresh([bool? enabled]) {
    final target = enabled ?? !_autoRefreshEnabled;
    if (target) {
      startAutoRefresh();
      refreshMatches(silent: true);
    } else {
      stopAutoRefresh();
    }
  }

  /// Configure a custom Backend API URL (e.g. your Vercel deployment URL) at runtime.
  Future<void> setCustomServerUrl(String? url) async {
    AppConstants.setCustomBaseUrl(url);
    await LocalStorageService.instance.saveCustomApiUrl(url);
    await refreshMatches(silent: false);
  }

  // ── Load Local Cache First, Then Sync with Cloud Backend ─────────────────
  Future<void> loadMatches() async {
    _isLoading = true;
    _safeNotify();

    // Load saved custom API URL if present
    final savedApiUrl = await LocalStorageService.instance.loadCustomApiUrl();
    if (savedApiUrl != null && savedApiUrl.isNotEmpty) {
      AppConstants.setCustomBaseUrl(savedApiUrl);
    }

    _pendingSyncMatchIds = await LocalStorageService.instance.loadPendingSyncIds();
    _matches = await LocalStorageService.instance.loadMatches();

    if (_matches.isNotEmpty && _selectedMatch == null) {
      final active = _matches.where((m) => m.isLive).firstOrNull ?? _matches.first;
      selectMatch(active);
    }

    _isLoading = false;
    _safeNotify();

    // Sync with cloud backend (Vercel + MongoDB Atlas) when running live
    if (_allowBackgroundTimers) {
      await refreshMatches(silent: true);
    }
  }

  /// Pull latest matches from shared cloud backend and push any pending local matches.
  Future<void> refreshMatches({bool silent = false}) async {
    if (_isRefreshing || _disposed) return;
    _isRefreshing = true;
    if (!silent) _safeNotify();

    try {
      // 1. Push any matches awaiting upload (including legacy local-only matches)
      final remoteBefore = await _apiService.fetchSharedMatches();
      final remoteById = {for (final m in remoteBefore) m.id: m};

      final toUpload = <MatchModel>[];
      for (final local in _matches) {
        if (_pendingSyncMatchIds.contains(local.id) || !remoteById.containsKey(local.id)) {
          toUpload.add(local);
        }
      }

      if (toUpload.isNotEmpty) {
        for (final m in toUpload) {
          try {
            final saved = await _apiService.upsertSharedMatch(m);
            remoteById[saved.id] = saved;
            _pendingSyncMatchIds.remove(m.id);
          } catch (_) {
            // Keep pending for retry
          }
        }
        await LocalStorageService.instance.savePendingSyncIds(_pendingSyncMatchIds);
      }

      // 2. Merge remote state while respecting active local edits
      final now = DateTime.now();
      final localById = {for (final m in _matches) m.id: m};
      final mergedMap = <String, MatchModel>{};

      for (final entry in remoteById.entries) {
        final id = entry.key;
        final remote = entry.value;
        final local = localById[id];
        final lastMut = _lastLocalMutationAt[id];
        final mutatedRecently = lastMut != null && now.difference(lastMut).inSeconds < 4;

        if (local != null &&
            (_pendingSyncMatchIds.contains(id) ||
                _queuedSyncPayload.containsKey(id) ||
                _activeSyncInFlight.contains(id) ||
                mutatedRecently)) {
          mergedMap[id] = local;
        } else {
          mergedMap[id] = remote;
        }
      }

      // Preserve any unsynced local matches not yet on server
      for (final local in _matches) {
        if (!mergedMap.containsKey(local.id) && _pendingSyncMatchIds.contains(local.id)) {
          mergedMap[local.id] = local;
        }
      }

      final mergedList = mergedMap.values.toList()
        ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

      _matches = mergedList;

      // Refresh selected match & innings snapshots for viewers watching live/scorecard
      if (_selectedMatch != null) {
        final updatedSelected = mergedMap[_selectedMatch!.id];
        if (updatedSelected != null) {
          final lastMut = _lastLocalMutationAt[updatedSelected.id];
          final mutatedRecently = lastMut != null && now.difference(lastMut).inSeconds < 4;
          final isActivelyEditingLocally = _pendingSyncMatchIds.contains(updatedSelected.id) ||
              _queuedSyncPayload.containsKey(updatedSelected.id) ||
              _activeSyncInFlight.contains(updatedSelected.id) ||
              mutatedRecently;
          if (!isActivelyEditingLocally) {
            _selectedMatch = updatedSelected;
            _firstInnings = updatedSelected.innings1;
            _secondInnings = updatedSelected.innings2;
            _currentInnings = updatedSelected.innings2 ?? updatedSelected.innings1;
          }
        }
      }

      await LocalStorageService.instance.saveMatches(_matches);
      _isCloudConnected = true;
      _syncError = null;
      _lastSyncedAt = DateTime.now();
    } catch (e) {
      _isCloudConnected = false;
      _syncError = e.toString();
    } finally {
      _isRefreshing = false;
      _safeNotify();
    }
  }

  void selectMatch(MatchModel match) {
    _selectedMatch = match;
    _firstInnings = match.innings1;
    _secondInnings = match.innings2;
    _currentInnings = match.innings2 ?? match.innings1;
    _undoStack.clear();
    _safeNotify();
  }

  // ── Create New Match with Custom Teams & Opening Players ──────────────────
  void createNewMatch({
    required String team1Name,
    required String team2Name,
    required String format,
    required int totalOvers,
    required int playersPerSide,
    required String tossWinner,
    required String tossDecision,
    required String strikerName,
    required String nonStrikerName,
    required String openingBowlerName,
  }) {
    final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';

    // Determine Batting and Bowling Teams based on Toss
    final String battingTeam = (tossDecision == 'bat')
        ? tossWinner
        : (tossWinner == team1Name ? team2Name : team1Name);
    final String bowlingTeam = (battingTeam == team1Name) ? team2Name : team1Name;

    final striker = BatterState(
      playerId: 'p_${DateTime.now().microsecondsSinceEpoch}_1',
      playerName: strikerName.trim().isEmpty ? 'Batter 1' : strikerName.trim(),
      runs: 0,
      balls: 0,
      fours: 0,
      sixes: 0,
      isOut: false,
      isStriker: true,
    );

    final nonStriker = BatterState(
      playerId: 'p_${DateTime.now().microsecondsSinceEpoch}_2',
      playerName: nonStrikerName.trim().isEmpty ? 'Batter 2' : nonStrikerName.trim(),
      runs: 0,
      balls: 0,
      fours: 0,
      sixes: 0,
      isOut: false,
      isStriker: false,
    );

    final bowler = BowlerState(
      playerId: 'p_${DateTime.now().microsecondsSinceEpoch}_3',
      playerName: openingBowlerName.trim().isEmpty ? 'Opening Bowler' : openingBowlerName.trim(),
      overs: 0,
      balls: 0,
      maidens: 0,
      runs: 0,
      wickets: 0,
      wides: 0,
      noBalls: 0,
      isCurrent: true,
    );

    final newInnings = InningsModel(
      id: 'inn_${matchId}_1',
      matchId: matchId,
      inningsNumber: 1,
      battingTeamId: battingTeam == team1Name ? 'team_1' : 'team_2',
      battingTeamName: battingTeam,
      bowlingTeamId: bowlingTeam == team1Name ? 'team_1' : 'team_2',
      bowlingTeamName: bowlingTeam,
      totalRuns: 0,
      totalWickets: 0,
      completedOvers: 0,
      currentBallInOver: 0,
      totalLegalBalls: 0,
      extras: const ExtrasBreakdown(wides: 0, noBalls: 0, byes: 0, legByes: 0, penalty: 0, total: 0),
      target: null,
      status: 'in_progress',
      currentBatters: [striker, nonStriker],
      battersUsed: [striker, nonStriker],
      bowlersUsed: [bowler],
      fallOfWickets: const [],
      thisOverBalls: const [],
    );

    final newMatch = MatchModel(
      id: matchId,
      team1Id: 'team_1',
      team2Id: 'team_2',
      team1Name: team1Name,
      team2Name: team2Name,
      format: format,
      totalOvers: totalOvers,
      status: 'in_progress',
      matchDate: DateTime.now(),
      venue: null,
      result: null,
      toss: TossInfo(
        winnerTeamId: tossWinner,
        decision: tossDecision,
      ),
      rules: MatchRules(
        ruleset: 'MCC_2026',
        maxOversPerBowler: 0, // No over limit per bowler as requested
        playersPerSide: playersPerSide,
        overLength: 6,
      ),
      innings1: newInnings,
      innings2: null,
    );

    _selectedMatch = newMatch;
    _currentInnings = newInnings;
    _firstInnings = newInnings;
    _secondInnings = null;
    _undoStack.clear();

    // Insert at top of matches list
    _matches.insert(0, newMatch);

    _persistMatches();
    notifyListeners();
  }

  // ── Side Change / Swap Strike Manually ────────────────────────────────────
  void swapStrike() {
    if (_currentInnings == null || _currentInnings!.currentBatters.length < 2) return;

    final updatedBatters = _currentInnings!.currentBatters.map((b) {
      return b.copyWith(isStriker: !b.isStriker);
    }).toList();

    _currentInnings = _currentInnings!.copyWith(currentBatters: updatedBatters);
    _syncBattersUsed();
    _updateCurrentInningsInMatch();
    _persistMatches();
    notifyListeners();
  }

  // ── Record a Delivery (Cricket Scoring Rules Engine) ───────────────────────
  BallResult recordBall({
    required int runs,
    required String extraType, // 'none', 'wide', 'no_ball', 'bye', 'leg_bye', 'penalty'
    int extraRuns = 0,
    bool isWicket = false,
    String? dismissalType,
    String? newBatterName,
    bool outIsStriker = true,
  }) {
    if (_currentInnings == null) return const BallResult();

    // 1. Push snapshot to undo stack
    _undoStack.add(_currentInnings!);

    final innings = _currentInnings!;
    final isLegal = extraType != 'wide' && extraType != 'no_ball';

    // 2. Runs calculation
    int batRuns = 0;
    int ballExtraRuns = 0;
    int totalBallRuns = 0;
    int bowlerConcededRuns = 0;
    String notation = '';

    if (extraType == 'wide') {
      // 1 penalty run for Wide + any additional runs completed by batters or boundary
      final additionalRuns = runs > 0 ? runs : (extraRuns > 0 ? extraRuns : 0);
      ballExtraRuns = 1 + additionalRuns;
      batRuns = 0;
      totalBallRuns = ballExtraRuns;
      bowlerConcededRuns = ballExtraRuns;
      notation = additionalRuns > 0 ? 'wd+$additionalRuns' : 'wd';
    } else if (extraType == 'no_ball') {
      // 1 penalty run for No Ball + runs scored off the bat
      final additionalRuns = runs > 0 ? runs : (extraRuns > 0 ? extraRuns : 0);
      ballExtraRuns = 1;
      batRuns = additionalRuns;
      totalBallRuns = ballExtraRuns + batRuns;
      bowlerConcededRuns = totalBallRuns;
      notation = batRuns > 0 ? 'nb+$batRuns' : 'nb';
    } else if (extraType == 'bye') {
      final byeRuns = runs > 0 ? runs : (extraRuns > 0 ? extraRuns : 1);
      ballExtraRuns = byeRuns;
      batRuns = 0;
      totalBallRuns = ballExtraRuns;
      bowlerConcededRuns = 0; // Byes do not count against bowler
      notation = 'b$ballExtraRuns';
    } else if (extraType == 'leg_bye') {
      final legByeRuns = runs > 0 ? runs : (extraRuns > 0 ? extraRuns : 1);
      ballExtraRuns = legByeRuns;
      batRuns = 0;
      totalBallRuns = ballExtraRuns;
      bowlerConcededRuns = 0; // Leg Byes do not count against bowler
      notation = 'lb$ballExtraRuns';
    } else {
      // Normal delivery
      batRuns = runs;
      ballExtraRuns = 0;
      totalBallRuns = runs;
      bowlerConcededRuns = runs;
      notation = isWicket ? (runs > 0 ? '${runs}W' : 'W') : '$runs';
    }

    // 3. Update Extras
    final extras = innings.extras.copyWith(
      wides: innings.extras.wides + (extraType == 'wide' ? ballExtraRuns : 0),
      noBalls: innings.extras.noBalls + (extraType == 'no_ball' ? ballExtraRuns : 0),
      byes: innings.extras.byes + (extraType == 'bye' ? ballExtraRuns : 0),
      legByes: innings.extras.legByes + (extraType == 'leg_bye' ? ballExtraRuns : 0),
      penalty: innings.extras.penalty + (extraType == 'penalty' ? ballExtraRuns : 0),
      total: innings.extras.total + ballExtraRuns,
    );

    // 4. Update Current Batters
    final currentBatters = List<BatterState>.from(innings.currentBatters);
    final strikerIdx = currentBatters.indexWhere((b) => b.isStriker);
    final nonStrikerIdx = currentBatters.indexWhere((b) => !b.isStriker);

    if (strikerIdx != -1) {
      final s = currentBatters[strikerIdx];
      currentBatters[strikerIdx] = s.copyWith(
        runs: s.runs + batRuns,
        balls: s.balls + (extraType == 'wide' ? 0 : 1), // Wide ball does not count as ball faced
        fours: s.fours + (batRuns == 4 ? 1 : 0),
        sixes: s.sixes + (batRuns == 6 ? 1 : 0),
      );
    }

    // 5. Update Current Bowler
    final bowlersUsed = List<BowlerState>.from(innings.bowlersUsed);
    final bowlerIdx = bowlersUsed.indexWhere((b) => b.isCurrent);
    if (bowlerIdx != -1) {
      final b = bowlersUsed[bowlerIdx];
      bowlersUsed[bowlerIdx] = b.copyWith(
        runs: b.runs + bowlerConcededRuns,
        balls: b.balls + (isLegal ? 1 : 0),
        wides: b.wides + (extraType == 'wide' ? 1 : 0),
        noBalls: b.noBalls + (extraType == 'no_ball' ? 1 : 0),
      );
    }

    // 6. Total Runs & Wickets
    int newTotalRuns = innings.totalRuns + totalBallRuns;
    int newTotalWickets = innings.totalWickets + (isWicket ? 1 : 0);

    // 7. Wicket handling
    final fallOfWickets = List<FallOfWicket>.from(innings.fallOfWickets);
    final battersUsed = List<BatterState>.from(innings.battersUsed);

    if (isWicket) {
      final dismissedIdx = outIsStriker ? strikerIdx : nonStrikerIdx;
      if (dismissedIdx != -1 && dismissedIdx < currentBatters.length) {
        final dismissed = currentBatters[dismissedIdx];

        fallOfWickets.add(FallOfWicket(
          wicketNumber: newTotalWickets,
          score: newTotalRuns,
          playerName: dismissed.playerName,
          overNumber: innings.completedOvers,
          ballNumber: innings.currentBallInOver + (isLegal ? 1 : 0),
        ));

        // Credit to bowler?
        final bowlerCredit = dismissalType != 'run_out' &&
            dismissalType != 'retired_out' &&
            dismissalType != 'retired_hurt';
        if (bowlerCredit && bowlerIdx != -1) {
          final b = bowlersUsed[bowlerIdx];
          bowlersUsed[bowlerIdx] = b.copyWith(wickets: b.wickets + 1);
        }

        // Update in battersUsed as out
        final usedIdx = battersUsed.indexWhere((b) => b.playerId == dismissed.playerId);
        if (usedIdx != -1) {
          battersUsed[usedIdx] = battersUsed[usedIdx].copyWith(
            isOut: true,
            dismissalType: dismissalType ?? 'out',
          );
        }

        // Replace dismissed batter with new batter if provided
        final newName = (newBatterName != null && newBatterName.trim().isNotEmpty)
            ? newBatterName.trim()
            : 'Batter ${battersUsed.length + 1}';

        final newBatter = BatterState(
          playerId: 'p_${DateTime.now().microsecondsSinceEpoch}',
          playerName: newName,
          runs: 0,
          balls: 0,
          fours: 0,
          sixes: 0,
          isOut: false,
          isStriker: outIsStriker,
        );

        currentBatters[dismissedIdx] = newBatter;
        battersUsed.add(newBatter);
      }
    }

    // 8. Strike rotation for runs
    // Odd runs rotate strike
    bool shouldRotate = false;
    if (extraType == 'bye' || extraType == 'leg_bye') {
      shouldRotate = ballExtraRuns % 2 != 0;
    } else if (extraType == 'wide') {
      shouldRotate = (ballExtraRuns - 1) % 2 != 0;
    } else {
      shouldRotate = batRuns % 2 != 0;
    }

    if (shouldRotate && currentBatters.length == 2) {
      currentBatters[0] = currentBatters[0].copyWith(isStriker: !currentBatters[0].isStriker);
      currentBatters[1] = currentBatters[1].copyWith(isStriker: !currentBatters[1].isStriker);
    }

    // 9. Over progress & Runs in current over
    final int overRunsBeforeBall = (innings.thisOverBalls.isEmpty) ? 0 : innings.thisOverRuns;
    final int newThisOverRuns = overRunsBeforeBall + bowlerConcededRuns;

    int newCompletedOvers = innings.completedOvers;
    int newBallInOver = innings.currentBallInOver;
    int newTotalLegalBalls = innings.totalLegalBalls;
    final thisOverBalls = List<String>.from(innings.thisOverBalls)..add(notation);
    bool overDone = false;

    if (isLegal) {
      newTotalLegalBalls++;
      newBallInOver++;

      if (newBallInOver >= 6) {
        overDone = true;
        newCompletedOvers++;
        newBallInOver = 0;

        // Bowler completed over: check for Maiden over (0 runs conceded by bowler in the 6-ball over)
        if (bowlerIdx != -1) {
          final b = bowlersUsed[bowlerIdx];
          final bool isMaiden = newThisOverRuns == 0;
          bowlersUsed[bowlerIdx] = b.copyWith(
            overs: b.overs + 1,
            balls: 0,
            maidens: b.maidens + (isMaiden ? 1 : 0),
          );
        }

        // End of over: Strike always changes ends!
        if (currentBatters.length == 2) {
          currentBatters[0] = currentBatters[0].copyWith(isStriker: !currentBatters[0].isStriker);
          currentBatters[1] = currentBatters[1].copyWith(isStriker: !currentBatters[1].isStriker);
        }
      }
    }

    // 10. Check Innings & Match Completion
    final totalMatchOvers = _selectedMatch?.totalOvers ?? 20;
    final playersCount = _selectedMatch?.rules.playersPerSide ?? 11;
    final maxWickets = playersCount - 1;

    bool innCompleted = false;
    bool matchCompleted = false;
    String? completionMsg;

    // Check if target chased down in 2nd innings
    if (innings.target != null && newTotalRuns >= innings.target!) {
      matchCompleted = true;
      final wicketsRemaining = maxWickets - newTotalWickets;
      final winDesc = '${innings.battingTeamName} won by $wicketsRemaining wickets!';
      completionMsg = winDesc;
      _updateMatchResult(winDesc, innings.battingTeamName);
    }
    // Check if overs complete or all out
    else if (newCompletedOvers >= totalMatchOvers || newTotalWickets >= maxWickets) {
      if (innings.inningsNumber == 1) {
        innCompleted = true;
        final target = newTotalRuns + 1;
        completionMsg = '1st Innings completed! Target: $target runs.';
      } else {
        // 2nd innings ended
        matchCompleted = true;
        final margin = (innings.target! - 1) - newTotalRuns;
        String winDesc;
        if (margin == 0) {
          winDesc = 'Match Tied!';
        } else if (margin > 0) {
          winDesc = '${innings.bowlingTeamName} won by $margin runs!';
        } else {
          winDesc = '${innings.battingTeamName} won by ${maxWickets - newTotalWickets} wickets!';
        }
        completionMsg = winDesc;
        _updateMatchResult(winDesc, margin > 0 ? innings.bowlingTeamName : innings.battingTeamName);
      }
    }

    _currentInnings = innings.copyWith(
      totalRuns: newTotalRuns,
      totalWickets: newTotalWickets,
      completedOvers: newCompletedOvers,
      currentBallInOver: newBallInOver,
      totalLegalBalls: newTotalLegalBalls,
      extras: extras,
      currentBatters: currentBatters,
      battersUsed: _mergeBatters(battersUsed, currentBatters),
      bowlersUsed: bowlersUsed,
      fallOfWickets: fallOfWickets,
      thisOverBalls: overDone ? [] : thisOverBalls,
      thisOverRuns: overDone ? 0 : newThisOverRuns,
      status: innCompleted || matchCompleted ? 'completed' : 'in_progress',
    );

    if (innings.inningsNumber == 1) {
      _firstInnings = _currentInnings;
    } else {
      _secondInnings = _currentInnings;
    }

    _updateCurrentInningsInMatch();
    _persistMatches();
    notifyListeners();

    return BallResult(
      overCompleted: overDone,
      inningsCompleted: innCompleted,
      matchCompleted: matchCompleted,
      isWicket: isWicket,
      message: completionMsg,
    );
  }

  // ── Set New Bowler ─────────────────────────────────────────────────────────
  void setNextBowler(String bowlerName) {
    if (_currentInnings == null || bowlerName.trim().isEmpty) return;

    final trimmed = bowlerName.trim();
    final bowlers = List<BowlerState>.from(_currentInnings!.bowlersUsed);

    for (int i = 0; i < bowlers.length; i++) {
      bowlers[i] = bowlers[i].copyWith(isCurrent: false);
    }

    final existingIdx = bowlers.indexWhere((b) => b.playerName.toLowerCase() == trimmed.toLowerCase());
    if (existingIdx != -1) {
      bowlers[existingIdx] = bowlers[existingIdx].copyWith(isCurrent: true);
    } else {
      bowlers.add(BowlerState(
        playerId: 'p_${DateTime.now().microsecondsSinceEpoch}',
        playerName: trimmed,
        overs: 0,
        balls: 0,
        maidens: 0,
        runs: 0,
        wickets: 0,
        wides: 0,
        noBalls: 0,
        isCurrent: true,
      ));
    }

    _currentInnings = _currentInnings!.copyWith(bowlersUsed: bowlers);
    _updateCurrentInningsInMatch();
    _persistMatches();
    notifyListeners();
  }

  // ── Start Second Innings ───────────────────────────────────────────────────
  void startSecondInnings({
    required String strikerName,
    required String nonStrikerName,
    required String openingBowlerName,
  }) {
    if (_selectedMatch == null || _firstInnings == null) return;

    final match = _selectedMatch!;
    final target = _firstInnings!.totalRuns + 1;

    // Batting and Bowling teams swap!
    final battingTeam = _firstInnings!.bowlingTeamName;
    final bowlingTeam = _firstInnings!.battingTeamName;

    final striker = BatterState(
      playerId: 'p_${DateTime.now().microsecondsSinceEpoch}_s2',
      playerName: strikerName.trim().isEmpty ? 'Batter 1' : strikerName.trim(),
      runs: 0,
      balls: 0,
      fours: 0,
      sixes: 0,
      isOut: false,
      isStriker: true,
    );

    final nonStriker = BatterState(
      playerId: 'p_${DateTime.now().microsecondsSinceEpoch}_ns2',
      playerName: nonStrikerName.trim().isEmpty ? 'Batter 2' : nonStrikerName.trim(),
      runs: 0,
      balls: 0,
      fours: 0,
      sixes: 0,
      isOut: false,
      isStriker: false,
    );

    final bowler = BowlerState(
      playerId: 'p_${DateTime.now().microsecondsSinceEpoch}_b2',
      playerName: openingBowlerName.trim().isEmpty ? 'Opening Bowler' : openingBowlerName.trim(),
      overs: 0,
      balls: 0,
      maidens: 0,
      runs: 0,
      wickets: 0,
      wides: 0,
      noBalls: 0,
      isCurrent: true,
    );

    final inn2 = InningsModel(
      id: 'inn_${match.id}_2',
      matchId: match.id,
      inningsNumber: 2,
      battingTeamId: 'team_2',
      battingTeamName: battingTeam,
      bowlingTeamId: 'team_1',
      bowlingTeamName: bowlingTeam,
      totalRuns: 0,
      totalWickets: 0,
      completedOvers: 0,
      currentBallInOver: 0,
      totalLegalBalls: 0,
      extras: const ExtrasBreakdown(wides: 0, noBalls: 0, byes: 0, legByes: 0, penalty: 0, total: 0),
      target: target,
      status: 'in_progress',
      currentBatters: [striker, nonStriker],
      battersUsed: [striker, nonStriker],
      bowlersUsed: [bowler],
      fallOfWickets: const [],
      thisOverBalls: const [],
    );

    _secondInnings = inn2;
    _currentInnings = inn2;
    _undoStack.clear();

    _updateCurrentInningsInMatch();
    _persistMatches();
    notifyListeners();
  }

  // ── Undo Last Ball ─────────────────────────────────────────────────────────
  void undoBall() {
    if (_undoStack.isEmpty) return;
    _currentInnings = _undoStack.removeLast();

    if (_currentInnings!.inningsNumber == 1) {
      _firstInnings = _currentInnings;
    } else {
      _secondInnings = _currentInnings;
    }

    _updateCurrentInningsInMatch();
    _persistMatches();
    notifyListeners();
  }

  // ── Internal Helpers ───────────────────────────────────────────────────────
  void _syncBattersUsed() {
    if (_currentInnings == null) return;
    final used = List<BatterState>.from(_currentInnings!.battersUsed);
    for (final cur in _currentInnings!.currentBatters) {
      final idx = used.indexWhere((b) => b.playerId == cur.playerId);
      if (idx != -1) {
        used[idx] = cur;
      }
    }
    _currentInnings = _currentInnings!.copyWith(battersUsed: used);
  }

  List<BatterState> _mergeBatters(List<BatterState> used, List<BatterState> current) {
    final result = List<BatterState>.from(used);
    for (final c in current) {
      final idx = result.indexWhere((b) => b.playerId == c.playerId);
      if (idx != -1) {
        result[idx] = c;
      } else {
        result.add(c);
      }
    }
    return result;
  }

  void _updateCurrentInningsInMatch() {
    if (_selectedMatch == null || _currentInnings == null) return;

    if (_currentInnings!.inningsNumber == 1) {
      _firstInnings = _currentInnings;
    } else {
      _secondInnings = _currentInnings;
    }

    _selectedMatch = _selectedMatch!.copyWith(
      innings1: _firstInnings,
      innings2: _secondInnings,
    );

    final idx = _matches.indexWhere((m) => m.id == _selectedMatch!.id);
    if (idx != -1) {
      _matches[idx] = _selectedMatch!;
    }
  }

  void _updateMatchResult(String description, String? winnerTeamName) {
    if (_selectedMatch == null) return;
    final res = MatchResult(
      type: 'completed',
      winnerTeamId: winnerTeamName,
      description: description,
    );
    _selectedMatch = _selectedMatch!.copyWith(
      status: 'completed',
      result: res,
      innings1: _firstInnings,
      innings2: _secondInnings,
    );

    final idx = _matches.indexWhere((m) => m.id == _selectedMatch!.id);
    if (idx != -1) {
      _matches[idx] = _selectedMatch!;
    }
  }

  void _persistMatches() {
    LocalStorageService.instance.saveMatches(_matches);
    final matchToSync = _selectedMatch;
    if (matchToSync != null && _allowBackgroundTimers) {
      _enqueueMatchSync(matchToSync);
    }
  }

  void _enqueueMatchSync(MatchModel match) {
    final id = match.id;
    _lastLocalMutationAt[id] = DateTime.now();
    _pendingSyncMatchIds.add(id);
    _queuedSyncPayload[id] = match;
    LocalStorageService.instance.savePendingSyncIds(_pendingSyncMatchIds);

    if (_activeSyncInFlight.contains(id)) return;
    _drainMatchSyncQueue(id);
  }

  Future<void> _drainMatchSyncQueue(String id) async {
    _activeSyncInFlight.add(id);
    try {
      while (_queuedSyncPayload.containsKey(id) && !_disposed) {
        final payload = _queuedSyncPayload.remove(id)!;
        try {
          await _apiService.upsertSharedMatch(payload);
          _isCloudConnected = true;
          _syncError = null;
          _lastSyncedAt = DateTime.now();

          if (!_queuedSyncPayload.containsKey(id)) {
            _pendingSyncMatchIds.remove(id);
            await LocalStorageService.instance.savePendingSyncIds(_pendingSyncMatchIds);
          }
          _safeNotify();
        } catch (e) {
          // Leave in _pendingSyncMatchIds so next auto/manual refresh retries
          _isCloudConnected = false;
          _syncError = e.toString();
          _safeNotify();
          break;
        }
      }
    } finally {
      _activeSyncInFlight.remove(id);
    }
  }

  Future<void> deleteMatch(String matchId) async {
    _matches.removeWhere((m) => m.id == matchId);
    _pendingSyncMatchIds.remove(matchId);
    _queuedSyncPayload.remove(matchId);
    if (_selectedMatch?.id == matchId) {
      _selectedMatch = _matches.firstOrNull;
      _firstInnings = _selectedMatch?.innings1;
      _secondInnings = _selectedMatch?.innings2;
      _currentInnings = _selectedMatch?.innings2 ?? _selectedMatch?.innings1;
    }
    await LocalStorageService.instance.saveMatches(_matches);
    await LocalStorageService.instance.savePendingSyncIds(_pendingSyncMatchIds);
    _safeNotify();

    if (_allowBackgroundTimers) {
      try {
        await _apiService.deleteSharedMatch(matchId);
      } catch (_) {}
    }
  }
}
