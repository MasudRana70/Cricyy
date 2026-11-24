// lib/providers/player_provider.dart

import 'package:flutter/foundation.dart';
import '../models/player_model.dart';
import '../models/match_model.dart';
import '../services/player_stats_aggregator.dart';

class PlayerProvider extends ChangeNotifier {
  List<PlayerAggregatedProfile> _profiles = [];
  PlayerAggregatedProfile? _selectedProfile;
  String? _selectedPlayerId;
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'runs'; // 'runs', 'wickets', 'matches', 'name'

  List<PlayerAggregatedProfile> get profiles => _filteredProfiles;
  List<PlayerModel> get players => _filteredProfiles.map((p) => p.player).toList();
  PlayerAggregatedProfile? get selectedProfile => _selectedProfile;
  PlayerModel? get selectedPlayer => _selectedProfile?.player;
  BattingStats? get battingStats => _selectedProfile?.battingStats;
  BowlingStats? get bowlingStats => _selectedProfile?.bowlingStats;
  List<PlayerMatchPerformance> get matchPerformances =>
      _selectedProfile?.matchPerformances ?? [];

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  int get totalPlayers => _profiles.length;

  List<PlayerAggregatedProfile> get _filteredProfiles {
    var list = _profiles;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) => p.player.name.toLowerCase().contains(q)).toList();
    }

    final sorted = List<PlayerAggregatedProfile>.from(list);
    if (_sortBy == 'runs') {
      sorted.sort((a, b) => b.battingStats.totalRuns.compareTo(a.battingStats.totalRuns));
    } else if (_sortBy == 'wickets') {
      sorted.sort((a, b) => b.bowlingStats.totalWickets.compareTo(a.bowlingStats.totalWickets));
    } else if (_sortBy == 'matches') {
      sorted.sort((a, b) => b.battingStats.totalMatches.compareTo(a.battingStats.totalMatches));
    } else if (_sortBy == 'name') {
      sorted.sort((a, b) => a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase()));
    }
    return sorted;
  }

  void updateFromMatches(List<MatchModel> matches) {
    _profiles = PlayerStatsAggregator.aggregateFromMatches(matches);
    if (_selectedPlayerId != null) {
      _selectedProfile = _profiles.where((p) => p.player.id == _selectedPlayerId).firstOrNull;
    } else if (_selectedProfile != null) {
      _selectedProfile = _profiles.where((p) => p.player.id == _selectedProfile!.player.id).firstOrNull;
    }
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void loadPlayerProfile(String playerId) {
    _selectedPlayerId = playerId;
    _selectedProfile = _profiles.where((p) => p.player.id == playerId).firstOrNull;
    notifyListeners();
  }
}
