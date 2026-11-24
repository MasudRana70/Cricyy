import 'package:flutter/material.dart';

/// Global color palette for Cricyy — Neomorphism / Minimalist design.
/// All colors are defined here — never hardcode colors elsewhere.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF1565C0); // Deeper cricket blue
  static const Color primaryDark   = Color(0xFF0D47A1);
  static const Color primaryLight  = Color(0xFFBBDEFB);
  static const Color accent        = Color(0xFFFF8F00); // Cricket amber

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF2E7D32);
  static const Color successLight  = Color(0xFFE8F5E9);
  static const Color warning       = Color(0xFFF57C00);
  static const Color warningLight  = Color(0xFFFFF3E0);
  static const Color error         = Color(0xFFB71C1C);
  static const Color errorLight    = Color(0xFFFFEBEE);

  // ── Neomorphism base ──────────────────────────────────────────────────────
  /// The single flat background that neomorphic shadows are cast on
  static const Color neoBackground = Color(0xFFECF0F5);
  /// Light shadow (top-left)
  static const Color neoShadowLight = Color(0xFFFFFFFF);
  /// Dark shadow (bottom-right)
  static const Color neoShadowDark  = Color(0xFFC8D0DB);
  /// Pressed / inset colour
  static const Color neoPressed     = Color(0xFFE4E9EE);

  // ── Neutral surfaces ──────────────────────────────────────────────────────
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color background    = Color(0xFFECF0F5); // matches neoBackground
  static const Color surfaceVariant= Color(0xFFF5F7FA);
  static const Color border        = Color(0xFFDDE3EA);
  static const Color borderLight   = Color(0xFFEEF2F6);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F1923);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textHint      = Color(0xFF9AA5B4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Scoring button colours ────────────────────────────────────────────────
  static const Color boundary      = Color(0xFF1565C0); // 4
  static const Color six           = Color(0xFF6A1B9A); // 6
  static const Color wicket        = Color(0xFFB71C1C); // W
  static const Color extra         = Color(0xFFBF360C); // wide/no-ball
  static const Color dot           = Color(0xFF37474F); // 0
  static const Color run           = Color(0xFF2E7D32); // 1–3

  // ── Innings ───────────────────────────────────────────────────────────────
  static const Color innings1      = Color(0xFF1565C0);
  static const Color innings2      = Color(0xFFFF8F00);

  // ── Live indicator ────────────────────────────────────────────────────────
  static const Color live          = Color(0xFFD32F2F);
}
