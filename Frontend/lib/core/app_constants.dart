import 'package:flutter/foundation.dart';

/// app_constants.dart — routes, API config, app-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Cricyy';

  /// Optional build-time override passed during Vercel / release builds:
  /// flutter build web --release --dart-define=API_BASE_URL=https://your-api.vercel.app/api
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Optional fallback production URL (update this once you deploy your Backend to Vercel
  /// if you don't want to pass --dart-define every time).
  static const String defaultProdBaseUrl = '';

  static String? _customOverrideUrl;

  static void setCustomBaseUrl(String? url) {
    final trimmed = url?.trim();
    _customOverrideUrl = (trimmed == null || trimmed.isEmpty) ? null : _normalizeApiUrl(trimmed);
  }

  static String? get customOverrideUrl => _customOverrideUrl;

  static String _normalizeApiUrl(String raw) {
    var clean = raw.trim().replaceAll(RegExp(r'/+$'), '');
    if (!clean.endsWith('/api')) {
      clean = '$clean/api';
    }
    return clean;
  }

  /// Active Backend API base URL:
  /// 1. User-configured runtime Server Sync URL (if set)
  /// 2. Compile-time --dart-define=API_BASE_URL (Vercel web / release APK)
  /// 3. defaultProdBaseUrl (if filled in)
  /// 4. Local development fallback (localhost:5000 on web/desktop, 10.0.2.2:5000 on Android)
  static String get baseUrl {
    if (_customOverrideUrl != null && _customOverrideUrl!.isNotEmpty) {
      return _customOverrideUrl!;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _normalizeApiUrl(_envBaseUrl);
    }
    if (defaultProdBaseUrl.isNotEmpty) {
      return _normalizeApiUrl(defaultProdBaseUrl);
    }
    return kIsWeb
        ? 'http://localhost:5000/api'
        : 'http://10.0.2.2:5000/api';
  }

  // Named routes
  static const String routeHome           = '/';
  static const String routeCreateMatch    = '/create-match';
  static const String routeLiveScoring    = '/live-scoring';
  static const String routeScorecard      = '/scorecard';
  static const String routeMatchHistory   = '/history';
  static const String routePlayerList     = '/players';
  static const String routePlayerProfile  = '/player-profile';
}
