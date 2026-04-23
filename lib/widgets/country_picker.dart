import 'package:country_picker/country_picker.dart' as cp;
import 'package:flutter/material.dart';

import '../data/countries.dart' as local;
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Spec §5.8 country picker — full ISO list, African markets pinned at top.
///
/// Wraps the `country_picker` package so we own the visual treatment and so
/// our screens can call a single function regardless of platform.
typedef OnCountrySelected = void Function(local.Country country);

void showCountryPickerSheet(
  BuildContext context, {
  required OnCountrySelected onSelected,
}) {
  cp.showCountryPicker(
    context: context,
    showPhoneCode: true,
    favorite: const ['GH', 'NG', 'KE', 'ZA', 'TZ', 'UG', 'RW', 'CI', 'SN'],
    countryListTheme: cp.CountryListThemeData(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomSheetHeight: MediaQuery.of(context).size.height * 0.85,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(VedgeSpacing.radiusXl),
      ),
      inputDecoration: InputDecoration(
        labelText: 'Search',
        hintText: 'Start typing to search',
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          borderSide: const BorderSide(color: VedgeColors.ink100),
        ),
      ),
      searchTextStyle: Theme.of(context).textTheme.bodyMedium,
      textStyle: Theme.of(context).textTheme.bodyLarge,
    ),
    onSelect: (cp.Country picked) {
      final country = local.Country(
        isoCode: picked.countryCode,
        name: picked.name,
        dialCode: '+${picked.phoneCode}',
        // The package gives Unicode flag glyphs only on iOS; on Android we
        // store the ISO code and render via emoji fallback.
        flagEmoji: picked.flagEmoji,
      );
      onSelected(country);
    },
  );
}
