import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Spec §5.7 — six-cell OTP input.
///
/// Implementation notes:
/// - Wraps a single hidden `TextField` (covers all six cells) so platform
///   autofill (`AutofillHints.oneTimeCode` → SMS Retriever on Android +
///   native iOS keyboard suggestion) works on the whole code at once.
/// - Each cell renders the n-th character of the controller's text. Pasting
///   anywhere fills all cells in order.
/// - Auto-submits on the [length]-th digit via [onCompleted].
/// - This deliberately does NOT use the `pin_code_fields` package (although
///   we depend on it for parity testing on iOS) — a bare TextField gives us
///   tighter control over a11y and reduces flakiness on cheap Android.
class OtpField extends StatefulWidget {
  const OtpField({
    required this.onCompleted,
    this.length = 6,
    this.errorText,
    this.isVerifying = false,
    this.controller,
    this.autofocus = true,
    super.key,
  });

  final ValueChanged<String> onCompleted;
  final int length;
  final String? errorText;
  final bool isVerifying;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    setState(() {});
    if (text.length == widget.length) {
      widget.onCompleted(text);
    }
  }

  @override
  void didUpdateWidget(covariant OtpField old) {
    super.didUpdateWidget(old);
    // If the parent cleared the code (e.g. after a verify error), refocus.
    if (old.errorText == null &&
        widget.errorText != null &&
        _controller.text.isNotEmpty) {
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final hasError = widget.errorText != null;
    final code = _controller.text;

    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      textField: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Visible cells.
              ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _focusNode.requestFocus(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(widget.length, (i) {
                      final ch = i < code.length ? code[i] : '';
                      final isFocusedCell =
                          !widget.isVerifying && code.length == i && _focusNode.hasFocus;
                      return Container(
                        width: 48,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasError
                                ? cs.error
                                : isFocusedCell
                                    ? cs.primary
                                    : cs.outline,
                            width: hasError || isFocusedCell ? 2 : 1.5,
                          ),
                        ),
                        child: Text(
                          ch,
                          style: t.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // Hidden text field that owns the actual input.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: AutofillGroup(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      enabled: !widget.isVerifying,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(widget.length),
                      ],
                      // showCursor false so the invisible cursor doesn't peek
                      // through on some Android skins.
                      showCursor: false,
                      style: const TextStyle(color: Colors.transparent),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.isVerifying) ...[
            const SizedBox(height: VedgeSpacing.space2),
            const LinearProgressIndicator(
              minHeight: 2,
              color: VedgeColors.ink900,
              backgroundColor: VedgeColors.ink050,
            ),
          ],
          if (hasError) ...[
            const SizedBox(height: 6),
            Text(
              widget.errorText!,
              style: t.bodySmall?.copyWith(color: cs.error),
            ),
          ],
        ],
      ),
    );
  }
}
