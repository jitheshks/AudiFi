import 'package:flutter/painting.dart';

/// Centralized border radius design tokens for Audifi.
abstract final class AppRadius {
  static const double xs = 8.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double pill = 20.0;
  static const double circular = 999.0;

  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusPill = BorderRadius.all(
    Radius.circular(pill),
  );
  static const BorderRadius radiusCircular = BorderRadius.all(
    Radius.circular(circular),
  );

  static const BorderRadius cardBorder = radiusXl;
  static const BorderRadius inputBorder = radiusLg;
  static const BorderRadius pillBorder = radiusPill;
}
