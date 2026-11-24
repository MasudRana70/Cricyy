// lib/services/match_api_service.dart

import '../models/match_model.dart';
import '../models/innings_model.dart';
import 'api_client.dart';

class MatchApiService {
  final ApiClient client;
  MatchApiService({ApiClient? client}) : client = client ?? ApiClient();

  // ── Shared Multi-User Cloud Sync Endpoints (/api/shared-matches) ─────────
  Future<List<MatchModel>> fetchSharedMatches({String? status, int limit = 100}) async {
    final query = <String, String>{
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final res = await client.get('/shared-matches', queryParams: query);
    if (res is Map && res['matches'] is List) {
      return (res['matches'] as List)
          .whereType<Map<String, dynamic>>()
          .map(MatchModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<MatchModel?> fetchSharedMatchById(String id) async {
    final res = await client.get('/shared-matches/$id');
    if (res is Map && res['match'] is Map<String, dynamic>) {
      return MatchModel.fromJson(res['match'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<MatchModel> upsertSharedMatch(MatchModel match, {String? deviceId}) async {
    final headers = <String, String>{
      if (deviceId != null && deviceId.isNotEmpty) 'X-Device-Id': deviceId,
    };
    final res = await client.put(
      '/shared-matches/${match.id}',
      body: match.toJson(),
      headers: headers.isEmpty ? null : headers,
    );
    if (res is Map && res['match'] is Map<String, dynamic>) {
      return MatchModel.fromJson(res['match'] as Map<String, dynamic>);
    }
    return match;
  }

  Future<void> deleteSharedMatch(String id, {required String creatorId}) async {
    await client.delete(
      '/shared-matches/$id',
      queryParams: {'creatorId': creatorId},
      headers: {'X-Device-Id': creatorId},
    );
  }

  Future<Map<String, dynamic>> checkHealth() async {
    final res = await client.get('/health');
    if (res is Map<String, dynamic>) return res;
    return {'status': 'unknown'};
  }

  // ── Legacy / Granular Match Endpoints (/api/matches) ─────────────────────
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
