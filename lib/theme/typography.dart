import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for vedge_patient.
///
/// Same Fraunces / Inter pairing as the staff app, but with a slightly
/// larger base size — patients include older adults on cheap phones.
class VedgePatientTypography {
  const VedgePatientTypography._();

  static TextTheme textTheme(TextTheme base, ColorScheme cs) {
    final display = GoogleFonts.frauncesTextTheme(base);
    final body = GoogleFonts.interTextTheme(base);

    return base.copyWith(
      displayLarge: display.displayLarge?.copyWith(color: cs.onSurface),
      displayMedium: display.displayMedium?.copyWith(color: cs.onSurface),
      displaySmall: display.displaySmall?.copyWith(color: cs.onSurface),
      headlineLarge: display.headlineLarge?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: body.titleLarge?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 20, // +2 over staff app
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: cs.onSurface,
        fontSize: 17, // +1
      ),
      titleSmall: body.titleSmall?.copyWith(color: cs.onSurface),
      bodyLarge: body.bodyLarge?.copyWith(
        color: cs.onSurface,
        fontSize: 17, // +1 over Material default
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: cs.onSurface,
        fontSize: 15, // +1
      ),
      bodySmall: body.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      labelLarge: body.labelLarge?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: body.labelMedium?.copyWith(color: cs.onSurfaceVariant),
      labelSmall: body.labelSmall?.copyWith(color: cs.onSurfaceVariant),
    );
  }
}
