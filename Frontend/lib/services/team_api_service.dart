// lib/services/team_api_service.dart

import '../models/match_model.dart';
import 'api_client.dart';

class TeamApiService {
  final ApiClient client;
  TeamApiService({ApiClient? client}) : client = client ?? ApiClient();

  Future<List<TeamModel>> getTeams({String? search, int page = 1, int limit = 20}) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await client.get('/teams', queryParams: query);
    if (res != null && res['teams'] is List) {
      return (res['teams'] as List).map((t) => TeamModel.fromJson(t)).toList();
    }
    return [];
  }

  Future<TeamModel> getTeamById(String id) async {
    final res = await client.get('/teams/$id');
    return TeamModel.fromJson(res['team']);
  }

  Future<TeamModel> createTeam(Map<String, dynamic> data) async {
    final res = await client.post('/teams', body: data);
    return TeamModel.fromJson(res['team']);
  }

  Future<TeamModel> addMember(String teamId, String playerId) async {
    final res = await client.post('/teams/$teamId/members', body: {'playerId': playerId});
    return TeamModel.fromJson(res['team']);
  }

  Future<TeamModel> removeMember(String teamId, String playerId) async {
    final res = await client.delete('/teams/$teamId/members/$playerId');
    return TeamModel.fromJson(res['team']);
  }
}
