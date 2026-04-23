import 'package:flutter_test/flutter_test.dart';
import 'package:vedge_patient/data/countries.dart';

void main() {
  group('Countries', () {
    test('default is Ghana', () {
      expect(Countries.defaultCountry.isoCode, 'GH');
      expect(Countries.defaultCountry.dialCode, '+233');
    });

    test('African markets come first in canonical order', () {
      final names = Countries.african.map((c) => c.isoCode).toList();
      expect(names.first, 'GH');
      expect(names.contains('NG'), isTrue);
      expect(names.contains('KE'), isTrue);
      expect(names.length, 9);
    });

    test('fromIsoCode is case-insensitive and finds known countries', () {
      expect(Countries.fromIsoCode('gh')?.dialCode, '+233');
      expect(Countries.fromIsoCode('NG')?.dialCode, '+234');
      expect(Countries.fromIsoCode('KE')?.dialCode, '+254');
      expect(Countries.fromIsoCode('US')?.dialCode, '+1');
    });

    test('fromIsoCode returns null for unknown', () {
      expect(Countries.fromIsoCode('ZZ'), isNull);
    });

    test('fromLocaleCountryCode falls back to Ghana on empty/null/unknown', () {
      expect(Countries.fromLocaleCountryCode(null).isoCode, 'GH');
      expect(Countries.fromLocaleCountryCode('').isoCode, 'GH');
      expect(Countries.fromLocaleCountryCode('XX').isoCode, 'GH');
    });

    test('fromLocaleCountryCode picks the right country when known', () {
      expect(Countries.fromLocaleCountryCode('NG').dialCode, '+234');
      expect(Countries.fromLocaleCountryCode('us').dialCode, '+1');
    });
  });
}
