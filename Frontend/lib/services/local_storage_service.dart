// lib/services/local_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_model.dart';

class LocalStorageService {
  static const String _keyMatches = 'cricyy_saved_matches';

  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  Future<void> saveMatches(List<MatchModel> matches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = matches.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_keyMatches, jsonString);
    } catch (e) {
      // Ignore or log storage error
    }
  }

  Future<List<MatchModel>> loadMatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyMatches);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((m) => MatchModel.fromJson(m as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Ignore or log error
    }
    return [];
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMatches);
  }
}
