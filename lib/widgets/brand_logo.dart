import 'package:flutter/material.dart';

import '../theme/colors.dart';

enum BrandLogoVariant { lockup, icon, wordmark }

/// Vedge Companion brand mark — Flutter port of the canonical
/// React component at
/// `vedge_frontend/src/components/branding/BrandLogo.tsx`.
///
/// **The React component is the source of truth, not the SVG files.**
/// SVGs in `vedge_frontend/public/brand/` are byte-identical exports for
/// non-React consumers (email, PDFs); the React rendering is what users
/// see on the dashboard + landing site, so that's what we mirror here.
///
/// Variants:
///   - `lockup`   (default) "vedge ■"   wordmark + clay accent square
///   - `icon`               [v] square   avatar / favicon form
///   - `wordmark`           "vedge"      wordmark alone
///
/// Sizing convention:
///   - `size` for lockup / wordmark == wordmark font-size in px.
///   - `size` for icon == the square's edge length in px.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    this.variant = BrandLogoVariant.lockup,
    this.size = 32,
    this.color,
    super.key,
  });

  final BrandLogoVariant variant;
  final double size;

  /// Override the wordmark color (defaults to `cs.onSurface` so the mark
  /// reads on both cream and ink surfaces). Only affects lockup + wordmark.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wordColor = color ?? Theme.of(context).colorScheme.onSurface;
    switch (variant) {
      case BrandLogoVariant.icon:
        return _Icon(size: size);
      case BrandLogoVariant.wordmark:
        return _Wordmark(color: wordColor, size: size);
      case BrandLogoVariant.lockup:
        return _Lockup(color: wordColor, size: size);
    }
  }
}

/// Wordmark style — exactly mirrors the React component:
///   - `font-display` → Fraunces (configured in pubspec)
///   - `tracking-tight` → letter-spacing −0.025em (i.e. −0.025 × fontSize)
///   - `lowercase` → "vedge" lowercase literal
///   - **Weight 400** per `BRANDING.md`: "the serif's own contrast gives
///     it presence without needing bold." Do NOT bump to SemiBold.
TextStyle _wordmarkStyle(Color color, double size) => TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.025 * size,
      color: color,
      height: 1.0,
    );

/// Lockup geometry — matches `BrandLogo.tsx` `WORDMARK_SIZES['md']`
/// scaled relative to fontSize. The React component aligns the accent
/// to the wordmark **baseline** then lifts it ~4px (md) / 6px (lg) /
/// 8px (xl) — consistently ~16% of fontSize above the baseline.
///
/// In Flutter we approximate `inline-flex items-baseline + translate-y`
/// with a bottom-aligned Row + a Padding.bottom that puts the accent
/// just above the wordmark's baseline.
class _Lockup extends StatelessWidget {
  const _Lockup({required this.color, required this.size});
  final Color color;
  final double size;

  /// Square edge as a fraction of wordmark fontSize. React uses
  /// 8/24 ≈ 33% for `md`, 10/40 = 25% for `lg`, 12/48 = 25% for `xl`.
  /// 30% sits in between and reads cleanly at `size: 32` (default).
  static const double _accentEdgeRatio = 0.30;

  /// Lift above wordmark baseline as a fraction of fontSize. React
  /// uses 4/24 = 16.7% (md), 6/40 = 15% (lg), 8/48 = 16.7% (xl).
  static const double _accentLiftAboveBaselineRatio = 0.16;

  /// Gap between wordmark right edge and accent left edge. React uses
  /// `gap-1.5` (6px) regardless of size; ~0.20 of fontSize is a close
  /// proportional fit at the sizes we use in the patient app (24–48 px).
  static const double _gapRatio = 0.20;

  /// Approximate distance from the wordmark line-box bottom up to the
  /// alphabetic baseline, as a fraction of fontSize. For Fraunces with
  /// `height: 1.0` this is ~20% (matches typical serif descent metrics).
  static const double _serifDescentRatio = 0.20;

  @override
  Widget build(BuildContext context) {
    final accentEdge = size * _accentEdgeRatio;
    // Accent bottom should sit at (descent − lift) above the row's
    // bottom edge, which equals `lift` above the wordmark baseline.
    final accentBottomPadding =
        (size * (_serifDescentRatio - _accentLiftAboveBaselineRatio))
            .clamp(0.0, double.infinity);

    return Semantics(
      label: 'Vedge',
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('vedge', style: _wordmarkStyle(color, size)),
            SizedBox(width: size * _gapRatio),
            Padding(
              padding: EdgeInsets.only(bottom: accentBottomPadding),
              child: Container(
                width: accentEdge,
                height: accentEdge,
                color: VedgeColors.clay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text('vedge', style: _wordmarkStyle(color, size));
  }
}

/// Icon mark — Flutter port of `IconMark` in `BrandLogo.tsx` for the
/// **patient-app variant** (cream bg + ink `v` + clay accent dot).
///
/// Canonical proportions from the React `IconMark` SVG:
///   - viewBox 64×64, corner radius 12  →  18.75% of edge
///   - clay accent 12×12 at (44, 8)     →  edge 18.75%, inset 12.5%
///   - `v` font-size 48 weight **400**, baseline y=50 → 78% from top
///
/// In Flutter, `Text('v', height: 1.0)` places the alphabetic baseline
/// at ~78% from the top of the text's own bounding box. To land at
/// 78% of the icon, we Align the text such that its center is below
/// the icon's geometric center — `Alignment(0, +0.12)`.
class _Icon extends StatelessWidget {
  const _Icon({required this.size});
  final double size;

  static const double _radiusRatio = 0.1875;
  static const double _accentEdgeRatio = 0.1875;
  static const double _accentInsetRatio = 0.125;
  static const double _glyphSizeRatio = 0.75;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vedge Companion',
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: VedgeColors.cream,
            borderRadius: BorderRadius.circular(size * _radiusRatio),
          ),
          child: Stack(
            children: [
              // Clay accent square, top-right inset (matches launcher icon).
              Positioned(
                top: size * _accentInsetRatio,
                right: size * _accentInsetRatio,
                child: Container(
                  width: size * _accentEdgeRatio,
                  height: size * _accentEdgeRatio,
                  color: VedgeColors.clay,
                ),
              ),
              // Ink `v`, Fraunces regular (weight 400 per the canonical
              // SVG and BRANDING.md). Pushed below geometric center so
              // its baseline lands at ~78% from the top of the icon.
              Align(
                alignment: const Alignment(0, 0.12),
                child: Text(
                  'v',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: size * _glyphSizeRatio,
                    fontWeight: FontWeight.w400,
                    color: VedgeColors.ink,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
