/// Compile-time feature flags. Values come from `--dart-define=`.
///
/// We keep this in one file so security-sensitive gates (verification code,
/// experimental teleconsult SDK, etc.) are visible at a glance.
class FeatureFlags {
  const FeatureFlags._();

  /// Spec §6.7 / spec implementation Q4 — gates the new OOB OTP flow.
  ///
  /// When **false** (the default for v1):
  ///  - The find-records flow does NOT call the legacy trust-based confirm
  ///    endpoint silently. The match card surfaces a "Verification coming
  ///    soon" message instead.
  ///  - The verify-link screen renders an explanatory state but does not POST
  ///    to the (not-yet-shipped) `/verify-with-code` endpoint.
  ///
  /// When **true**: the verify-link screen is fully functional and the
  /// find-records "Yes, this is me" CTA routes into it.
  ///
  /// This protects the security review's #1 P0: no degraded auto-confirm of
  /// cross-tenant PHI access.
  static const bool verificationCodeEnabled =
      bool.fromEnvironment('VERIFICATION_CODE_ENABLED', defaultValue: false);
}
