// lib/services/statistics_api_service.dart

import '../models/player_model.dart';
import 'api_client.dart';

class StatisticsApiService {
  final ApiClient client;
  StatisticsApiService({ApiClient? client}) : client = client ?? ApiClient();

  Future<Map<String, dynamic>> getPlayerStatistics(String playerId, {String? format, String? fromDate, String? toDate}) async {
    final query = <String, String>{};
    if (format != null && format.isNotEmpty && format != 'all') query['format'] = format;
    if (fromDate != null) query['fromDate'] = fromDate;
    if (toDate != null) query['toDate'] = toDate;
    final res = await client.get('/players/$playerId/statistics', queryParams: query.isEmpty ? null : query);
    return {
      'batting': res['batting'] != null ? BattingStats.fromJson(res['batting']) : BattingStats.empty(),
      'bowling': res['bowling'] != null ? BowlingStats.fromJson(res['bowling']) : BowlingStats.empty(),
    };
  }

  Future<Map<String, dynamic>> getPlayerHistory(String playerId, {String? format, int page = 1, int limit = 20}) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (format != null && format.isNotEmpty && format != 'all') {
      query['format'] = format;
    }
    final res = await client.get('/players/$playerId/history', queryParams: query);
    return {
      'records': res['records'] is List ? (res['records'] as List) : [],
      'pagination': res['pagination'],
    };
  }
}
