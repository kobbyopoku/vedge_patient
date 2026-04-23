import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/countries.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'country_picker.dart';

/// Spec §5.8 — country code + national number, joined visually.
class PhoneField extends StatelessWidget {
  const PhoneField({
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.errorText,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final Country country;
  final ValueChanged<Country> onCountryChanged;
  final String? errorText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
            border: Border.all(
              color: errorText != null ? cs.error : cs.outline,
              width: 1.5,
            ),
          ),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label:
                      'Country code: ${country.name}, ${country.dialCode}. Tap to change.',
                  child: ExcludeSemantics(
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(VedgeSpacing.radiusMd),
                      ),
                      onTap: () => showCountryPickerSheet(
                        context,
                        onSelected: onCountryChanged,
                      ),
                      child: Container(
                        // 110 was 4px tight on Samsung with dial codes like
                        // +233 / +256 — bump to 124 so 4-digit codes fit
                        // without horizontal-flex overflow.
                        width: 124,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(country.flagEmoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(country.dialCode,
                                style: t.titleMedium?.copyWith(
                                    color: cs.onSurface)),
                            const SizedBox(width: 4),
                            Icon(Icons.unfold_more_rounded,
                                size: 16, color: cs.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: cs.outline,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: autofocus,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                    ],
                    style: t.titleMedium,
                    decoration: InputDecoration(
                      hintText: '244 000 0000',
                      hintStyle: t.titleMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: t.bodySmall?.copyWith(color: VedgeColors.critical),
          ),
        ],
      ],
    );
  }
}
