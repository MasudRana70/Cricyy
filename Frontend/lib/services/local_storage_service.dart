// lib/services/local_storage_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_model.dart';

class LocalStorageService {
  static const String _keyMatches = 'cricyy_saved_matches';
  static const String _keyApiUrl  = 'cricyy_custom_api_url';
  static const String _keyPendingSync = 'cricyy_pending_sync_ids';
  static const String _keyDeviceId = 'cricyy_device_id';

  static String? _cachedDeviceId;

  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static String _generateDeviceId() {
    final rand = Random.secure().nextInt(0x3fffffff).toRadixString(36);
    return 'dev_${DateTime.now().microsecondsSinceEpoch}_$rand';
  }

  String getOrInitDeviceIdSync() {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final id = _generateDeviceId();
    _cachedDeviceId = id;
    _persistDeviceIdIfAbsent(id);
    return id;
  }

  Future<void> _persistDeviceIdIfAbsent(String fallbackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_keyDeviceId);
      if (existing != null && existing.trim().isNotEmpty) {
        _cachedDeviceId = existing.trim();
      } else {
        await prefs.setString(_keyDeviceId, fallbackId);
      }
    } catch (_) {}
  }

  Future<String> getOrCreateDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_keyDeviceId);
      if (existing != null && existing.trim().isNotEmpty) {
        _cachedDeviceId = existing.trim();
        return _cachedDeviceId!;
      }
      final id = _cachedDeviceId ?? _generateDeviceId();
      _cachedDeviceId = id;
      await prefs.setString(_keyDeviceId, id);
      return id;
    } catch (_) {
      return _cachedDeviceId ??= _generateDeviceId();
    }
  }

  Future<void> saveMatches(List<MatchModel> matches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = matches.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_keyMatches, jsonString);
    } catch (_) {
      // Ignore storage error in restricted environments
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
    } catch (_) {
      // Ignore parse error
    }
    return [];
  }

  Future<void> saveCustomApiUrl(String? url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url == null || url.trim().isEmpty) {
        await prefs.remove(_keyApiUrl);
      } else {
        await prefs.setString(_keyApiUrl, url.trim());
      }
    } catch (_) {}
  }

  Future<String?> loadCustomApiUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyApiUrl);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePendingSyncIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyPendingSync, ids.toList());
    } catch (_) {}
  }

  Future<Set<String>> loadPendingSyncIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingSync);
      return list != null ? list.toSet() : <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMatches);
    await prefs.remove(_keyPendingSync);
  }
}
