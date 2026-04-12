/// Spacing tokens — 8px base unit with patient-app tap targets ≥ 48px.
class VedgePatientSpacing {
  const VedgePatientSpacing._();

  static const double unit = 8.0;

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Primary button / list row minimum height. 56 instead of the staff
  /// app's 52 — shaky hands, cheap phones, outdoor lighting.
  static const double minTapHeight = 56.0;

  /// Minimum square touch target per Material a11y spec.
  static const double minTapSquare = 48.0;
}
