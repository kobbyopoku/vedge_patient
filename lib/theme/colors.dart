import 'package:flutter/material.dart';

/// Vedge Companion design tokens. Active palette: clay / ink / cream.
/// Source of truth: vedge_frontend/BRANDING.md (Apr 2026 rebrand).
///
/// The teal-700 era is over. Anything still pulling teal is a bug.
class VedgeColors {
  const VedgeColors._();

  // --- Brand anchors (locked, do not modify without brand review) ---
  static const Color clay = Color(0xFFC8553D); // accent / CTA only
  static const Color ink = Color(0xFF0E2319); // primary text + brand "green"
  static const Color cream = Color(0xFFF3ECDF); // surface / background

  // --- Clay scale (used very sparingly) ---
  static const Color clay50 = Color(0xFFFBEEEB);
  static const Color clay100 = Color(0xFFF6D5CE);
  static const Color clay500 = Color(0xFFC8553D); // = clay
  static const Color clay600 = Color(0xFFB04832);
  static const Color clay700 = Color(0xFF8B3826);

  // --- Ink scale (text, dividers, inverse surfaces) ---
  static const Color ink900 = Color(0xFF0E2319); // = ink, primary text
  static const Color ink700 = Color(0xFF1F3A2F); // secondary text
  static const Color ink500 = Color(0xFF526E5F); // tertiary text / muted icons
  static const Color ink300 = Color(0xFF95AAA0); // disabled
  static const Color ink100 = Color(0xFFD2DBD5); // dividers on cream
  static const Color ink050 = Color(0xFFE8EDEA); // subtle field backgrounds

  // --- Cream scale (surfaces) ---
  static const Color cream50 = Color(0xFFFBF7F0); // raised surfaces
  static const Color cream100 = Color(0xFFF3ECDF); // = cream, scaffold bg
  static const Color cream200 = Color(0xFFEAE0CE); // pressed / hover overlay base

  // --- Semantic (clinical state) ---
  // Accessible against cream100 to >= 4.5:1 contrast.
  static const Color positive = Color(0xFF2D6A4F); // "within range"
  static const Color positiveBg = Color(0xFFD7E8DD);
  // Spec §4.1 listed B45309 with claimed 4.7:1 on cream; actual measured
  // contrast was 4.07:1 on cautionBg (fails AA for the pill text). Darkened
  // by ~10% to A34809 → 4.88:1 on cautionBg, 5.12:1 on cream. Documented in
  // tasks/vedge-companion-build-status.md as a deliberate spec deviation.
  static const Color caution = Color(0xFFA34809); // "flagged"
  static const Color cautionBg = Color(0xFFF8E5C7);
  static const Color critical = Color(0xFFB42318); // "critical"
  static const Color criticalBg = Color(0xFFF7D5D0);
  static const Color info = Color(0xFF1E466B); // info / neutral status
  static const Color infoBg = Color(0xFFD7E2EE);

  // --- Dark theme anchors ---
  static const Color inkSurface = Color(0xFF0E2319); // dark scaffold bg
  static const Color inkSurfaceElevated = Color(0xFF1A2E25); // dark cards
  static const Color creamOnInk = Color(0xFFF3ECDF); // "cream" text on ink

  // --- Overlays ---
  static const Color hover = Color(0x14000000); // 8% black on light surfaces
  static const Color press = Color(0x26000000); // 15% black

  // --- Reserved (do NOT use as brand colors; only as raw badges if needed) ---
  static const Color scrim = Color(0x80000000);
}

/// Builds a Material 3 ColorScheme aligned with the Vedge Companion palette.
/// Use this in vedge_patient_app.dart instead of ColorScheme.fromSeed().
ColorScheme buildVedgeLightScheme() => const ColorScheme.light(
      brightness: Brightness.light,
      primary: VedgeColors.ink, // ink anchors hierarchy
      onPrimary: VedgeColors.cream,
      primaryContainer: VedgeColors.ink050,
      onPrimaryContainer: VedgeColors.ink,
      secondary: VedgeColors.clay, // clay = accent
      onSecondary: Colors.white,
      secondaryContainer: VedgeColors.clay50,
      onSecondaryContainer: VedgeColors.clay700,
      tertiary: VedgeColors.info,
      onTertiary: Colors.white,
      error: VedgeColors.critical,
      onError: Colors.white,
      errorContainer: VedgeColors.criticalBg,
      onErrorContainer: VedgeColors.critical,
      surface: VedgeColors.cream,
      onSurface: VedgeColors.ink,
      surfaceContainerHighest: VedgeColors.cream50,
      surfaceContainerHigh: VedgeColors.cream50,
      surfaceContainer: VedgeColors.cream50,
      surfaceContainerLow: VedgeColors.cream,
      surfaceContainerLowest: VedgeColors.cream,
      surfaceTint: Colors.transparent, // we want flat surfaces, not tinted
      onSurfaceVariant: VedgeColors.ink500,
      outline: VedgeColors.ink100,
      outlineVariant: VedgeColors.ink050,
      inverseSurface: VedgeColors.ink,
      onInverseSurface: VedgeColors.cream,
      inversePrimary: VedgeColors.clay,
      scrim: VedgeColors.scrim,
      shadow: Color(0xFF000000),
    );

ColorScheme buildVedgeDarkScheme() => const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: VedgeColors.cream, // invert: cream is the anchor on dark
      onPrimary: VedgeColors.ink,
      primaryContainer: Color(0xFF243B30),
      onPrimaryContainer: VedgeColors.cream,
      secondary: VedgeColors.clay, // clay still = accent
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF3A1A12),
      onSecondaryContainer: VedgeColors.clay100,
      tertiary: Color(0xFF9CB6D1),
      onTertiary: VedgeColors.ink,
      error: Color(0xFFE57368),
      onError: VedgeColors.ink,
      errorContainer: Color(0xFF3F1410),
      onErrorContainer: Color(0xFFF7D5D0),
      surface: VedgeColors.inkSurface,
      onSurface: VedgeColors.cream,
      surfaceContainerHighest: VedgeColors.inkSurfaceElevated,
      surfaceContainerHigh: VedgeColors.inkSurfaceElevated,
      surfaceContainer: VedgeColors.inkSurfaceElevated,
      surfaceContainerLow: VedgeColors.inkSurface,
      surfaceContainerLowest: VedgeColors.inkSurface,
      surfaceTint: Colors.transparent,
      onSurfaceVariant: Color(0xFFB6C4BC),
      outline: Color(0xFF3A4F44),
      outlineVariant: Color(0xFF24332B),
      inverseSurface: VedgeColors.cream,
      onInverseSurface: VedgeColors.ink,
      inversePrimary: VedgeColors.ink,
      scrim: VedgeColors.scrim,
      shadow: Color(0xFF000000),
    );

/// Backwards-compat shim during the rolling rebrand. Old call sites referenced
/// `VedgePatientColors.primary` / `.surfaceLight` / etc. — those token names
/// don't exist in the new palette, so this redirect maps them to the closest
/// equivalent so the app keeps building while screens are rewritten.
///
/// DO NOT add new uses. Use [VedgeColors] directly.
@Deprecated('Use VedgeColors. This shim exists only to keep the legacy walking '
    'skeleton building during the Vedge Companion rebrand.')
class VedgePatientColors {
  const VedgePatientColors._();

  static const Color primary = VedgeColors.ink;
  static const Color primaryDark = VedgeColors.ink;
  static const Color primaryContainerLight = VedgeColors.ink050;

  static const Color surfaceLight = VedgeColors.cream;
  static const Color surfaceLightElevated = VedgeColors.cream50;

  static const Color surfaceDark = VedgeColors.inkSurface;
  static const Color surfaceDarkElevated = VedgeColors.inkSurfaceElevated;

  static const Color abnormal = VedgeColors.caution;
  static const Color critical = VedgeColors.critical;
  static const Color ok = VedgeColors.positive;

  static const Color subtleBorder = VedgeColors.ink100;
}
