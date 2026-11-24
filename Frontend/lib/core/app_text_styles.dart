import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Global typography system.
/// Built on Inter for body/UI and a mono-style for cricket numbers.
class AppTextStyles {
  AppTextStyles._();

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get display => GoogleFonts.inter(
    fontSize: 48, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -1.5,
  );

  static TextStyle get headline1 => GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );

  static TextStyle get headline2 => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );

  static TextStyle get headline3 => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Score (monospace-feel for numbers) ────────────────────────────────────
  static TextStyle get scoreLarge => GoogleFonts.inter(
    fontSize: 56, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -2,
  );

  static TextStyle get scoreMedium => GoogleFonts.inter(
    fontSize: 36, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -1,
  );

  static TextStyle get scoreSmall => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get body1 => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );

  static TextStyle get body2 => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  static TextStyle get bodyBold => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 0.3,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textHint, letterSpacing: 0.5,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  // ── Button ────────────────────────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary, letterSpacing: 0.1,
  );

  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  // ── Scoring button (large, easy to tap) ───────────────────────────────────
  static TextStyle get scoringButton => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static TextStyle get scoringButtonSmall => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  // ── Table / Stats ─────────────────────────────────────────────────────────
  static TextStyle get tableHeader => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textHint, letterSpacing: 0.6,
  );

  static TextStyle get tableCell => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get tableCellBold => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
