import 'package:flutter_test/flutter_test.dart';
import 'package:vedge_patient/core/security/safe_url_launcher.dart';

void main() {
  group('isUrlAllowed (security P0 allowlist)', () {
    test('allows https with a host', () {
      expect(isUrlAllowed(Uri.parse('https://vedge.health/legal/terms')),
          isTrue);
      expect(isUrlAllowed(Uri.parse('https://paystack.com/checkout/abc')),
          isTrue);
    });

    test('refuses https with empty host', () {
      expect(isUrlAllowed(Uri.parse('https://')), isFalse);
      expect(isUrlAllowed(Uri.parse('https:///path')), isFalse);
    });

    test('allows tel:, mailto:, vedge:// schemes', () {
      expect(isUrlAllowed(Uri.parse('tel:+233244000000')), isTrue);
      expect(isUrlAllowed(Uri.parse('mailto:hello@vedge.health')), isTrue);
      expect(isUrlAllowed(Uri.parse('vedge://payment-return?ref=xyz')), isTrue);
    });

    test('refuses dangerous / unexpected schemes', () {
      const refused = [
        'http://example.com',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'intent://com.evil.app#Intent;scheme=https;end',
        'app://launch/me',
        'sms:+1',
        'ftp://example.com/file',
        'data:text/html,<script>alert(1)</script>',
      ];
      for (final raw in refused) {
        expect(isUrlAllowed(Uri.parse(raw)), isFalse,
            reason: 'should refuse: $raw');
      }
    });

    test('refuses scheme-less / empty inputs', () {
      expect(isUrlAllowed(Uri.parse('')), isFalse);
      expect(isUrlAllowed(Uri.parse('//host/path')), isFalse);
    });
  });
}
