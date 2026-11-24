// lib/services/match_api_service.dart

import '../models/match_model.dart';
import '../models/innings_model.dart';
import 'api_client.dart';

class MatchApiService {
  final ApiClient client;
  MatchApiService({ApiClient? client}) : client = client ?? ApiClient();

  Future<List<MatchModel>> getMatches({String? status, String? team, int page = 1, int limit = 20}) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (team != null && team.isNotEmpty) 'team': team,
    };
    final res = await client.get('/matches', queryParams: query);
    if (res != null && res['matches'] is List) {
      return (res['matches'] as List).map((m) => MatchModel.fromJson(m)).toList();
    }
    return [];
  }

  Future<MatchModel> getMatchById(String id) async {
    final res = await client.get('/matches/$id');
    return MatchModel.fromJson(res['match']);
  }

  Future<MatchModel> createMatch(Map<String, dynamic> data) async {
    final res = await client.post('/matches', body: data);
    return MatchModel.fromJson(res['match']);
  }

  Future<InningsModel> startInnings(String matchId, Map<String, dynamic> data) async {
    final res = await client.post('/matches/$matchId/innings', body: data);
    return InningsModel.fromJson(res['innings']);
  }

  Future<List<InningsModel>> getInnings(String matchId) async {
    final res = await client.get('/matches/$matchId/innings');
    if (res != null && res['innings'] is List) {
      return (res['innings'] as List).map((i) => InningsModel.fromJson(i)).toList();
    }
    return [];
  }

  Future<MatchModel> completeMatch(String matchId) async {
    final res = await client.post('/matches/$matchId/complete');
    return MatchModel.fromJson(res['match']);
  }

  Future<Map<String, dynamic>> getScorecard(String matchId) async {
    final res = await client.get('/matches/$matchId/scorecard');
    return res['scorecard'] as Map<String, dynamic>? ?? {};
  }
}
