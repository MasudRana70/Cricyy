// lib/services/scoring_api_service.dart

import '../models/innings_model.dart';
import 'api_client.dart';

class ScoringApiService {
  final ApiClient client;
  ScoringApiService({ApiClient? client}) : client = client ?? ApiClient();

  Future<Map<String, dynamic>> recordDelivery(String matchId, Map<String, dynamic> deliveryData) async {
    final res = await client.post('/matches/$matchId/deliveries', body: deliveryData);
    return {
      'delivery': res['delivery'],
      'innings': res['innings'] != null ? InningsModel.fromJson(res['innings']) : null,
      'inningsComplete': res['inningsComplete'] ?? false,
      'completionReason': res['completionReason'],
    };
  }

  Future<Map<String, dynamic>> undoDelivery(String matchId, String inningsId) async {
    final res = await client.post('/matches/$matchId/undo', body: {'inningsId': inningsId});
    return {
      'innings': res['innings'] != null ? InningsModel.fromJson(res['innings']) : null,
      'undoneDelivery': res['undoneDelivery'],
    };
  }

  Future<List<dynamic>> getDeliveries(String matchId, {String? inningsId, int? overNumber}) async {
    final query = <String, String>{};
    if (inningsId != null) query['inningsId'] = inningsId;
    if (overNumber != null) query['overNumber'] = overNumber.toString();
    final res = await client.get('/matches/$matchId/deliveries', queryParams: query.isEmpty ? null : query);
    return (res != null && res['deliveries'] is List) ? res['deliveries'] as List : [];
  }
}
