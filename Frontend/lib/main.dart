// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/app_constants.dart';
import 'providers/match_provider.dart';
import 'providers/player_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/match/create_match_screen.dart';
import 'screens/scoring/live_scoring_screen.dart';
import 'screens/scorecard/scorecard_screen.dart';
import 'screens/history/match_history_screen.dart';
import 'screens/player/player_profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const CricyyApp());
}

class CricyyApp extends StatelessWidget {
  const CricyyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProxyProvider<MatchProvider, PlayerProvider>(
          create: (_) => PlayerProvider(),
          update: (_, matchProv, playerProv) =>
              (playerProv ?? PlayerProvider())..updateFromMatches(matchProv.matches),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppConstants.routeHome,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeHome:
        return _slide(const HomeScreen());

      case AppConstants.routeCreateMatch:
        return _slide(const CreateMatchScreen());

      case AppConstants.routeLiveScoring:
        return _slide(const LiveScoringScreen());

      case AppConstants.routeScorecard:
        return _slide(const ScorecardScreen());

      case AppConstants.routeMatchHistory:
        return _slide(const MatchHistoryScreen());

      case AppConstants.routePlayerProfile:
        final id = settings.arguments as String? ?? 'p1';
        return _slide(PlayerProfileScreen(playerId: id));

      default:
        return _slide(const HomeScreen());
    }
  }

  PageRoute _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, anim, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
