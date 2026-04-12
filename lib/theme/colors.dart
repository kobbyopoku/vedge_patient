import 'package:flutter/material.dart';

/// Design tokens for the patient app.
///
/// Shares the teal-700 primary with vedge_frontend + vedge_staff, but swaps
/// in a softer, warmer surface palette — the patient app should feel calmer
/// and more human than the clinical staff tool.
class VedgePatientColors {
  const VedgePatientColors._();

  /// Tailwind teal-700 — same primary used everywhere in the Vedge ecosystem.
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryContainerLight = Color(0xFFDFF4F0);

  /// Warmer surface tint (vs staff app's cool #F8FAFA).
  static const Color surfaceLight = Color(0xFFFBF8F4);
  static const Color surfaceLightElevated = Color(0xFFFFFFFF);

  static const Color surfaceDark = Color(0xFF101715);
  static const Color surfaceDarkElevated = Color(0xFF1B2320);

  /// Accents for abnormal / critical lab flags.
  static const Color abnormal = Color(0xFFF59E0B); // amber
  static const Color critical = Color(0xFFDC2626); // red
  static const Color ok = Color(0xFF0F766E); // teal (primary)

  static const Color subtleBorder = Color(0xFFEADFD0);
}
