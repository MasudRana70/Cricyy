import 'package:flutter/material.dart';

/// Global color palette for Cricyy.
/// All colors are defined here — never hardcode colors elsewhere.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF1B6CA8); // Deep cricket blue
  static const Color primaryDark   = Color(0xFF0D4E80);
  static const Color primaryLight  = Color(0xFFD6E9F8);
  static const Color accent        = Color(0xFFE8A020); // Cricket gold

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF2E7D32);
  static const Color successLight  = Color(0xFFE8F5E9);
  static const Color warning       = Color(0xFFF57C00);
  static const Color warningLight  = Color(0xFFFFF3E0);
  static const Color error         = Color(0xFFC62828);
  static const Color errorLight    = Color(0xFFFFEBEE);

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color background    = Color(0xFFF4F6F9);
  static const Color surfaceVariant= Color(0xFFF0F4F8);
  static const Color border        = Color(0xFFDDE3EA);
  static const Color borderLight   = Color(0xFFEEF2F6);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F1923);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textHint      = Color(0xFF9AA5B4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Scoring ───────────────────────────────────────────────────────────────
  static const Color boundary      = Color(0xFF1B6CA8); // 4 or 6
  static const Color six           = Color(0xFF6B21A8); // six
  static const Color wicket        = Color(0xFFC62828); // W
  static const Color extra         = Color(0xFFB45309); // wide/no-ball
  static const Color dot           = Color(0xFF4A5568); // 0
  static const Color run           = Color(0xFF2E7D32); // 1–3

  // ── Innings ───────────────────────────────────────────────────────────────
  static const Color innings1      = Color(0xFF1B6CA8);
  static const Color innings2      = Color(0xFFE8A020);

  // ── Live indicator ────────────────────────────────────────────────────────
  static const Color live          = Color(0xFFDC2626);
}
