/// Vedge Companion spacing + sizing tokens.
///
/// Base unit: 4px. We use a 4-step scale for finer control on dense
/// clinical lists, but everything composes off the base unit.
class VedgeSpacing {
  const VedgeSpacing._();

  static const double unit = 4.0;

  // Spacing scale
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0; // default card padding
  static const double space5 = 20.0;
  static const double space6 = 24.0; // default screen padding
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;

  // Radii
  static const double radiusXs = 6.0; // pills, badges
  static const double radiusSm = 10.0; // chips, small inputs
  static const double radiusMd = 14.0; // inputs, buttons
  static const double radiusLg = 16.0; // cards
  static const double radiusXl = 24.0; // bottom sheets, large hero panels
  static const double radiusFull = 9999.0;

  // Touch targets
  static const double tapMin = 48.0; // Material a11y minimum
  static const double tapComfortable = 56.0; // primary buttons + list rows

  // App chrome
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 76.0; // 72 + 4 for label cushion

  // Motion (Duration ms)
  static const int motionFast = 150;
  static const int motionNormal = 250;
  static const int motionSlow = 400;
  static const int motionRefresh = 800; // pull-to-refresh max

  // Elevation (we use borders + subtle shadows, not Material elevation)
  static const double cardBorderWidth = 1.0;
  static const double cardShadowBlur = 12.0;
  static const double cardShadowSpread = 0.0;
  static const double cardShadowOpacityLight = 0.03; // ~rgba(14,35,25,0.03)
  static const double cardShadowOpacityDark = 0.6;
}

/// Backwards-compat shim during the rolling rebrand. Keeps the legacy walking
/// skeleton building while screens are rewritten.
@Deprecated('Use VedgeSpacing.')
class VedgePatientSpacing {
  const VedgePatientSpacing._();

  static const double unit = 4.0;

  static const double xs = VedgeSpacing.space1;
  static const double sm = VedgeSpacing.space2;
  static const double md = VedgeSpacing.space4;
  static const double lg = VedgeSpacing.space6;
  static const double xl = VedgeSpacing.space8;
  static const double xxl = VedgeSpacing.space12;

  static const double minTapHeight = VedgeSpacing.tapComfortable;
  static const double minTapSquare = VedgeSpacing.tapMin;
}
