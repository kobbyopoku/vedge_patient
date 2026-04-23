import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedge_patient/theme/colors.dart';

/// WCAG-2 relative luminance (sRGB → linearized → weighted).
/// Uses the Flutter 3.32+ float-component API (.r/.g/.b are 0..1).
double _relativeLuminance(Color c) {
  final r = _channel(c.r);
  final g = _channel(c.g);
  final b = _channel(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _channel(double v) => v <= 0.03928
    ? v / 12.92
    : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double contrastRatio(Color fg, Color bg) {
  final lf = _relativeLuminance(fg);
  final lb = _relativeLuminance(bg);
  final lighter = math.max(lf, lb);
  final darker = math.min(lf, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // Body-text combinations must meet WCAG AA (4.5:1).
  group('VedgeColors WCAG AA body-text contrast (>= 4.5:1)', () {
    final bodyPairs = <(String, Color, Color)>[
      ('ink900 on cream', VedgeColors.ink900, VedgeColors.cream),
      ('ink500 on cream', VedgeColors.ink500, VedgeColors.cream),
      ('cream on inkSurface (dark)', VedgeColors.cream, VedgeColors.inkSurface),
      ('critical on cream', VedgeColors.critical, VedgeColors.cream),
      ('positive on cream', VedgeColors.positive, VedgeColors.cream),
      ('info on cream', VedgeColors.info, VedgeColors.cream),
      // Pill foregrounds against their own backgrounds (the actual production
      // combination — pills never put state colors on the bare cream scaffold).
      ('positive on positiveBg', VedgeColors.positive, VedgeColors.positiveBg),
      ('caution on cautionBg', VedgeColors.caution, VedgeColors.cautionBg),
      ('critical on criticalBg', VedgeColors.critical, VedgeColors.criticalBg),
      ('info on infoBg', VedgeColors.info, VedgeColors.infoBg),
    ];
    for (final p in bodyPairs) {
      test(p.$1, () {
        final r = contrastRatio(p.$2, p.$3);
        expect(
          r >= 4.5,
          isTrue,
          reason: '${p.$1} ratio is ${r.toStringAsFixed(2)} (must be >= 4.5)',
        );
      });
    }
  });

  // Accent-only combinations must meet WCAG AA Large (3:1) — these tokens
  // are used as accent UI (clay icon button bg, caution as chip background)
  // and never as body text. See colors.dart docstring + spec §5.3.
  group('VedgeColors WCAG AA-Large accent contrast (>= 3:1)', () {
    final accentPairs = <(String, Color, Color)>[
      ('clay on cream', VedgeColors.clay, VedgeColors.cream),
      ('caution on cream', VedgeColors.caution, VedgeColors.cream),
      ('cream on clay', VedgeColors.cream, VedgeColors.clay),
    ];
    for (final p in accentPairs) {
      test(p.$1, () {
        final r = contrastRatio(p.$2, p.$3);
        expect(
          r >= 3.0,
          isTrue,
          reason: '${p.$1} ratio is ${r.toStringAsFixed(2)} (must be >= 3.0)',
        );
      });
    }
  });

  group('Brand anchors locked', () {
    test('clay is C8553D', () {
      expect(VedgeColors.clay.toARGB32() & 0x00FFFFFF, 0xC8553D);
    });
    test('ink is 0E2319', () {
      expect(VedgeColors.ink.toARGB32() & 0x00FFFFFF, 0x0E2319);
    });
    test('cream is F3ECDF', () {
      expect(VedgeColors.cream.toARGB32() & 0x00FFFFFF, 0xF3ECDF);
    });
  });

  group('Built ColorSchemes', () {
    test('light: primary is ink, surface is cream, scheme is light', () {
      final s = buildVedgeLightScheme();
      expect(s.brightness, Brightness.light);
      expect(s.primary, VedgeColors.ink);
      expect(s.surface, VedgeColors.cream);
      expect(s.secondary, VedgeColors.clay);
    });

    test('dark: surface is inkSurface, primary is cream', () {
      final s = buildVedgeDarkScheme();
      expect(s.brightness, Brightness.dark);
      expect(s.primary, VedgeColors.cream);
      expect(s.surface, VedgeColors.inkSurface);
    });

    test('surfaceTint is transparent in both modes (flat surfaces)', () {
      expect(buildVedgeLightScheme().surfaceTint, Colors.transparent);
      expect(buildVedgeDarkScheme().surfaceTint, Colors.transparent);
    });
  });
}
