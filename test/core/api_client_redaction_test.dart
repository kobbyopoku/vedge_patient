import 'package:flutter_test/flutter_test.dart';
import 'package:vedge_patient/core/api/api_client.dart';

void main() {
  group('redactedHeadersForTest (security P0)', () {
    test('redacts Authorization (case-insensitive)', () {
      final r = redactedHeadersForTest({'Authorization': 'Bearer abc.def.ghi'});
      expect(r['Authorization'], '<redacted>');
    });

    test('redacts Cookie + Set-Cookie', () {
      final r = redactedHeadersForTest({
        'Cookie': 'session=xyz',
        'set-cookie': 'session=xyz',
      });
      expect(r['Cookie'], '<redacted>');
      expect(r['set-cookie'], '<redacted>');
    });

    test('redacts anything containing "token" or "secret" in name', () {
      final r = redactedHeadersForTest({
        'X-Refresh-Token': 'rt-abc',
        'X-Client-Secret': 'cs-abc',
        'X-Random': 'value',
      });
      expect(r['X-Refresh-Token'], '<redacted>');
      expect(r['X-Client-Secret'], '<redacted>');
      expect(r['X-Random'], 'value');
    });

    test('preserves non-sensitive headers verbatim', () {
      final r = redactedHeadersForTest({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });
      expect(r['Accept'], 'application/json');
      expect(r['Content-Type'], 'application/json');
    });
  });
}
