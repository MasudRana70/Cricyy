import 'package:flutter/material.dart';

/// Spacing constants — use these everywhere instead of raw numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double base= 16;
  static const double lg  = 20;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl= 48;

  // Page padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsets pageHPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(20);

  // Gaps
  static const SizedBox gapXS  = SizedBox(height: xs,  width: xs);
  static const SizedBox gapSM  = SizedBox(height: sm,  width: sm);
  static const SizedBox gapMD  = SizedBox(height: md,  width: md);
  static const SizedBox gapBase= SizedBox(height: base,width: base);
  static const SizedBox gapLG  = SizedBox(height: lg,  width: lg);
  static const SizedBox gapXL  = SizedBox(height: xl,  width: xl);
  static const SizedBox gapXXL = SizedBox(height: xxl, width: xxl);

  static SizedBox hGap(double w) => SizedBox(width: w);
  static SizedBox vGap(double h) => SizedBox(height: h);
}

/// Border radius constants
class AppRadius {
  AppRadius._();

  static const double xs  = 6;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double full= 100;

  static BorderRadius get rXS  => BorderRadius.circular(xs);
  static BorderRadius get rSM  => BorderRadius.circular(sm);
  static BorderRadius get rMD  => BorderRadius.circular(md);
  static BorderRadius get rLG  => BorderRadius.circular(lg);
  static BorderRadius get rXL  => BorderRadius.circular(xl);
  static BorderRadius get rXXL => BorderRadius.circular(xxl);
  static BorderRadius get rFull=> BorderRadius.circular(full);
}
