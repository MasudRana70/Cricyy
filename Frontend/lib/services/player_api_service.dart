// lib/services/player_api_service.dart

import '../models/player_model.dart';
import 'api_client.dart';

class PlayerApiService {
  final ApiClient client;
  PlayerApiService({ApiClient? client}) : client = client ?? ApiClient();

  Future<List<PlayerModel>> getPlayers({String? search, int page = 1, int limit = 20}) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await client.get('/players', queryParams: query);
    if (res != null && res['players'] is List) {
      return (res['players'] as List).map((p) => PlayerModel.fromJson(p)).toList();
    }
    return [];
  }

  Future<PlayerModel> getPlayerById(String id) async {
    final res = await client.get('/players/$id');
    return PlayerModel.fromJson(res['player']);
  }

  Future<PlayerModel> createPlayer(Map<String, dynamic> data) async {
    final res = await client.post('/players', body: data);
    return PlayerModel.fromJson(res['player']);
  }

  Future<PlayerModel> updatePlayer(String id, Map<String, dynamic> data) async {
    final res = await client.put('/players/$id', body: data);
    return PlayerModel.fromJson(res['player']);
  }

  Future<void> deletePlayer(String id) async {
    await client.delete('/players/$id');
  }
}
