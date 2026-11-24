import 'package:flutter/foundation.dart';

/// app_constants.dart — routes, API config, app-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Cricyy';

  // API base URL
  // On Web (Chrome) or Windows desktop: localhost:5000
  // On Android emulator: 10.0.2.2:5000
  static String get baseUrl => kIsWeb
      ? 'http://localhost:5000/api'
      : 'http://10.0.2.2:5000/api';

  // Named routes
  static const String routeHome           = '/';
  static const String routeCreateMatch    = '/create-match';
  static const String routeLiveScoring    = '/live-scoring';
  static const String routeScorecard      = '/scorecard';
  static const String routeMatchHistory   = '/history';
  static const String routePlayerList     = '/players';
  static const String routePlayerProfile  = '/player-profile';
}
