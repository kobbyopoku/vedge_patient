import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Vedge Companion button. Five variants × three sizes.
///
/// See spec §5.1 for the visual contract. Use [primary] ONCE per screen.
/// Use [accent] (clay) only for celebratory delight moments.
enum VedgeButtonVariant { primary, secondary, tertiary, destructive, accent }

enum VedgeButtonSize { large, medium, small }

class VedgeButton extends StatelessWidget {
  const VedgeButton({
    required this.label,
    required this.onPressed,
    this.variant = VedgeButtonVariant.primary,
    this.size = VedgeButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final VedgeButtonVariant variant;
  final VedgeButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticLabel;

  bool get _isDisabled => onPressed == null || isLoading;

  double get _height {
    switch (size) {
      case VedgeButtonSize.large:
        return VedgeSpacing.tapComfortable; // 56
      case VedgeButtonSize.medium:
        return 44;
      case VedgeButtonSize.small:
        return 36;
    }
  }

  EdgeInsets get _hPadding {
    switch (size) {
      case VedgeButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: VedgeSpacing.space6);
      case VedgeButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 18);
      case VedgeButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: VedgeSpacing.space3);
    }
  }

  TextStyle? _textStyle(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return size == VedgeButtonSize.small ? t.labelMedium : t.labelLarge;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = _resolveColors(cs);
    final textStyle = _textStyle(context)?.copyWith(color: colors.fg);

    final content = isLoading
        ? SizedBox(
            height: textStyle?.fontSize ?? 16,
            width: textStyle?.fontSize ?? 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(colors.fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.fg),
                const SizedBox(width: VedgeSpacing.space2 + 2),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: VedgeSpacing.space2 + 2),
                Icon(trailingIcon, size: 18, color: colors.fg),
              ],
            ],
          );

    final button = Material(
      color: colors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
        side: colors.border == null
            ? BorderSide.none
            : BorderSide(color: colors.border!, width: 1.5),
      ),
      child: InkWell(
        onTap: _isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
        splashColor: colors.fg.withValues(alpha: 0.08),
        highlightColor: colors.fg.withValues(alpha: 0.04),
        child: Padding(
          padding: _hPadding,
          child: Center(child: content),
        ),
      ),
    );

    final sized = SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: Opacity(
        opacity: _isDisabled && !isLoading ? 0.40 : 1.0,
        child: button,
      ),
    );

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      label: semanticLabel ?? label,
      liveRegion: isLoading,
      child: ExcludeSemantics(child: sized),
    );
  }

  _ButtonColors _resolveColors(ColorScheme cs) {
    switch (variant) {
      case VedgeButtonVariant.primary:
        return _ButtonColors(bg: cs.primary, fg: cs.onPrimary);
      case VedgeButtonVariant.secondary:
        return _ButtonColors(
          bg: Colors.transparent,
          fg: cs.primary,
          border: cs.primary,
        );
      case VedgeButtonVariant.tertiary:
        return _ButtonColors(bg: Colors.transparent, fg: cs.primary);
      case VedgeButtonVariant.destructive:
        return _ButtonColors(bg: cs.error, fg: Colors.white);
      case VedgeButtonVariant.accent:
        return const _ButtonColors(bg: VedgeColors.clay, fg: VedgeColors.cream);
    }
  }
}

class _ButtonColors {
  const _ButtonColors({required this.bg, required this.fg, this.border});
  final Color bg;
  final Color fg;
  final Color? border;
}
