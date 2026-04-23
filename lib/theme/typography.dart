import 'package:flutter/material.dart';

/// Vedge Companion typography. Two families:
///   - Fraunces (variable serif): display + headline ONLY
///   - Inter:                     body, labels, transactional UI, buttons
///
/// Rule of thumb: if the user might *act* on the text (button, label,
/// form field, list row), it's Inter. If we're *welcoming* or *announcing*
/// (screen title, hero copy), it's Fraunces.
///
/// Sizes are absolute; we do NOT scale by `MediaQuery.textScaler` overrides.
/// Flutter handles text scaling natively; we pick base sizes generous
/// enough to remain readable on a 5.5" 720p screen at default scale.
///
/// Both families are bundled as variable-axis TTFs under
/// `assets/fonts/`. Flutter maps `fontWeight: FontWeight.w600` through
/// to the variable font's `wght` axis automatically — no `FontVariation`
/// gymnastics needed for the weights we use (400 + 600).
class VedgeTypography {
  const VedgeTypography._();

  static const String _serif = 'Fraunces';
  static const String _sans = 'Inter';

  static TextTheme textTheme(ColorScheme cs) {
    return TextTheme(
      // Display — used on welcome / hero panels only.
      displayLarge: TextStyle(
        fontFamily: _serif,
        fontSize: 40,
        height: 1.1,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: _serif,
        fontSize: 32,
        height: 1.15,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: _serif,
        fontSize: 26,
        height: 1.2,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),

      // Headline — screen titles / section heroes.
      headlineLarge: TextStyle(
        fontFamily: _serif,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: _serif,
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: _serif,
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),

      // Title — card titles, list row primary text.
      titleLarge: TextStyle(
        fontFamily: _sans,
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
        letterSpacing: -0.1,
      ),
      titleMedium: TextStyle(
        fontFamily: _sans,
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: _sans,
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),

      // Body — running prose, list secondary text.
      bodyLarge: TextStyle(
        fontFamily: _sans,
        fontSize: 17,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: _sans,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: _sans,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: cs.onSurfaceVariant,
      ),

      // Label — buttons, chips, form labels.
      labelLarge: TextStyle(
        fontFamily: _sans,
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: cs.onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: _sans,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: cs.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontFamily: _sans,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: cs.onSurfaceVariant,
      ),
    );
  }

  /// One-off accessor for the wordmark style — used by BrandLogo.
  static TextStyle wordmark(Color color) => TextStyle(
        fontFamily: _serif,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: color,
      );
}

/// Backwards-compat shim during the rolling rebrand.
@Deprecated('Use VedgeTypography. This shim exists only to keep the legacy '
    'walking skeleton building during the Vedge Companion rebrand.')
class VedgePatientTypography {
  const VedgePatientTypography._();

  static TextTheme textTheme(TextTheme base, ColorScheme cs) =>
      VedgeTypography.textTheme(cs);
}
