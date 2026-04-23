/// Country list with flag emoji, ISO code and dial code, used by [PhoneField]
/// + [CountryPicker]. Africa-first ordering: the markets named in the spec
/// (Ghana, Nigeria, Kenya, South Africa, Tanzania, Uganda, Rwanda,
/// Côte d'Ivoire, Senegal) are pinned at the top, then the rest A→Z.
///
/// This is intentionally a tiny static list — the `country_picker` package
/// dependency provides the full ISO list via its own UI. We use this list
/// only when we need a quick lookup or fallback.
class Country {
  const Country({
    required this.isoCode,
    required this.name,
    required this.dialCode,
    required this.flagEmoji,
  });

  final String isoCode; // ISO-3166 alpha-2
  final String name;
  final String dialCode; // includes leading '+'
  final String flagEmoji;

  String get displayLabel => '$flagEmoji  $name  $dialCode';

  /// Join a user-typed national number with this country's dial code into
  /// an E.164 string. Strips whitespace and — critically — any single
  /// trunk-zero prefix (Ghana/UK/NG/SA/many African countries teach users
  /// to write their number as "0244 XXX XXX", then append a '0' that
  /// belongs *before* the NSN, not after the country code). Without this,
  /// "+233" + "0244435025" produces "+2330244435025" which libphonenumber
  /// rejects server-side → false 400 on /start.
  ///
  /// Example: Country(GH, "+233").toE164("0244 435 025") → "+233244435025".
  String toE164(String localDigits) {
    final stripped = localDigits.replaceAll(RegExp(r'\s+'), '');
    final withoutTrunk = stripped.startsWith('0') ? stripped.substring(1) : stripped;
    return '$dialCode$withoutTrunk';
  }
}

class Countries {
  const Countries._();

  /// Spec-defined African market priorities (top of picker).
  static const List<Country> african = [
    Country(isoCode: 'GH', name: 'Ghana', dialCode: '+233', flagEmoji: '🇬🇭'),
    Country(isoCode: 'NG', name: 'Nigeria', dialCode: '+234', flagEmoji: '🇳🇬'),
    Country(isoCode: 'KE', name: 'Kenya', dialCode: '+254', flagEmoji: '🇰🇪'),
    Country(isoCode: 'ZA', name: 'South Africa', dialCode: '+27', flagEmoji: '🇿🇦'),
    Country(isoCode: 'TZ', name: 'Tanzania', dialCode: '+255', flagEmoji: '🇹🇿'),
    Country(isoCode: 'UG', name: 'Uganda', dialCode: '+256', flagEmoji: '🇺🇬'),
    Country(isoCode: 'RW', name: 'Rwanda', dialCode: '+250', flagEmoji: '🇷🇼'),
    Country(isoCode: 'CI', name: "Côte d'Ivoire", dialCode: '+225', flagEmoji: '🇨🇮'),
    Country(isoCode: 'SN', name: 'Senegal', dialCode: '+221', flagEmoji: '🇸🇳'),
  ];

  /// Default country per spec §12.4.
  static const Country defaultCountry = Country(
    isoCode: 'GH',
    name: 'Ghana',
    dialCode: '+233',
    flagEmoji: '🇬🇭',
  );

  /// A short global supplement — when the device locale isn't African and we
  /// need a fallback while the user opens the full picker.
  static const List<Country> globalCommon = [
    Country(isoCode: 'US', name: 'United States', dialCode: '+1', flagEmoji: '🇺🇸'),
    Country(isoCode: 'GB', name: 'United Kingdom', dialCode: '+44', flagEmoji: '🇬🇧'),
    Country(isoCode: 'CA', name: 'Canada', dialCode: '+1', flagEmoji: '🇨🇦'),
    Country(isoCode: 'IN', name: 'India', dialCode: '+91', flagEmoji: '🇮🇳'),
    Country(isoCode: 'AE', name: 'United Arab Emirates', dialCode: '+971', flagEmoji: '🇦🇪'),
  ];

  /// Lookup by ISO code (returns null if unknown).
  static Country? fromIsoCode(String isoCode) {
    final normalized = isoCode.toUpperCase();
    for (final c in [...african, ...globalCommon]) {
      if (c.isoCode == normalized) return c;
    }
    return null;
  }

  /// Resolve the default country from a device locale's `countryCode`.
  /// Falls back to Ghana per spec §12.4.
  static Country fromLocaleCountryCode(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return defaultCountry;
    return fromIsoCode(countryCode) ?? defaultCountry;
  }
}
