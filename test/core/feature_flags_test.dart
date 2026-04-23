import 'package:flutter_test/flutter_test.dart';
import 'package:vedge_patient/core/config/feature_flags.dart';

void main() {
  test('VERIFICATION_CODE_ENABLED defaults to false (security gate)', () {
    expect(FeatureFlags.verificationCodeEnabled, isFalse,
        reason:
            'The default MUST be false. Tests run without --dart-define so '
            'this proves we never silently fall back to the legacy '
            'trust-based confirm in production.');
  });
}
