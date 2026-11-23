import 'package:flutter/widgets.dart';

/// Centralized spacing tokens for Audifi.
/// Standardizes margins, padding, and gaps across screens.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double xxxl = 32.0;

  // Common Page Padding matching `.pad` in Audifi HTML reference
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: base,
  );
  static const EdgeInsets card = EdgeInsets.all(base);
  static const EdgeInsets cardLarge = EdgeInsets.all(lg);
  static const EdgeInsets pill = EdgeInsets.symmetric(
    horizontal: base,
    vertical: 9.0,
  );
  static const EdgeInsets searchField = EdgeInsets.symmetric(
    horizontal: base,
    vertical: 14.0,
  );

  // Vertical Gaps
  static const SizedBox vGap2 = SizedBox(height: 2.0);
  static const SizedBox vGap4 = SizedBox(height: xs);
  static const SizedBox vGap6 = SizedBox(height: 6.0);
  static const SizedBox vGap8 = SizedBox(height: sm);
  static const SizedBox vGap10 = SizedBox(height: 10.0);
  static const SizedBox vGap12 = SizedBox(height: md);
  static const SizedBox vGap16 = SizedBox(height: base);
  static const SizedBox vGap20 = SizedBox(height: lg);
  static const SizedBox vGap24 = SizedBox(height: xl);
  static const SizedBox vGap28 = SizedBox(height: xxl);
  static const SizedBox vGap32 = SizedBox(height: xxxl);

  // Horizontal Gaps
  static const SizedBox hGap4 = SizedBox(width: xs);
  static const SizedBox hGap8 = SizedBox(width: sm);
  static const SizedBox hGap12 = SizedBox(width: md);
  static const SizedBox hGap16 = SizedBox(width: base);
  static const SizedBox hGap20 = SizedBox(width: lg);
  static const SizedBox hGap24 = SizedBox(width: xl);
}
