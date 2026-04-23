import 'package:flutter_test/flutter_test.dart';
import 'package:vedge_patient/data/lab_glossary.dart';

void main() {
  group('LabGlossary', () {
    test('has at least the 30 most common tests defined', () {
      expect(LabGlossary.size, greaterThanOrEqualTo(30));
    });

    test('finds GLU by code', () {
      final r = LabGlossary.lookup(code: 'GLU');
      expect(r, isNotNull);
      expect(r!.title.toLowerCase(), contains('fasting glucose'));
    });

    test('finds HbA1c by canonical short code', () {
      final r = LabGlossary.lookup(code: 'HBA1C');
      expect(r, isNotNull);
      expect(r!.blurb, contains('two to three months'));
    });

    test('finds HbA1c by LOINC', () {
      final r = LabGlossary.lookup(code: '4548-4');
      expect(r, isNotNull);
    });

    test('case-insensitive code lookup', () {
      expect(LabGlossary.lookup(code: 'hgb'), isNotNull);
      expect(LabGlossary.lookup(code: 'HGB'), isNotNull);
    });

    test('falls back to test name match', () {
      final r = LabGlossary.lookup(name: 'Hemoglobin');
      expect(r, isNotNull);
      expect(r!.title, contains('Hemoglobin'));
    });

    test('returns null for unknown codes (no "unknown" placeholder)', () {
      expect(LabGlossary.lookup(code: 'XXXXX-FOO'), isNull);
      expect(LabGlossary.lookup(name: 'Mystery test'), isNull);
      expect(LabGlossary.lookup(), isNull);
      expect(LabGlossary.lookup(code: '', name: ''), isNull);
    });

    test('handles whitespace gracefully', () {
      expect(LabGlossary.lookup(code: '  glu  '), isNotNull);
      expect(LabGlossary.lookup(name: '  hemoglobin  '), isNotNull);
    });
  });
}
