import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../data/countries.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/phone_field.dart';
import '../../widgets/vedge_button.dart';
import 'otp_screen.dart';

/// Spec §6.2 — one phone field, one Get Started button.
///
/// V128 phone-first flow: tapping Get Started calls POST /api/patient/auth/start
/// (enumeration-safe 202 regardless of whether the phone is already a
/// registered account), then routes to [OtpScreen] to verify the code. The
/// verify response decides whether the user lands straight in the app
/// (existing account) or at [CompleteProfileScreen] to finish signup
/// (new account).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _phoneCtrl = TextEditingController();
  Country _country = Countries.defaultCountry;
  bool _submitting = false;
  String? _phoneError;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('welcome_seen');
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _digits => _phoneCtrl.text.replaceAll(RegExp(r'\s+'), '');

  String get _e164 => _country.toE164(_phoneCtrl.text);

  bool get _isValid {
    // Count effective NSN digits after trunk-zero stripping, so "0244..."
    // and "244..." are treated the same length-wise.
    final effective = _digits.startsWith('0') ? _digits.substring(1) : _digits;
    return effective.length >= 7;
  }

  Future<void> _getStarted() async {
    if (!_isValid) {
      setState(() => _phoneError = 'Enter your phone number');
      return;
    }
    final telemetry = ref.read(telemetryProvider);
    telemetry.track('welcome_cta_start');

    setState(() {
      _submitting = true;
      _phoneError = null;
      _error = null;
    });

    try {
      await ref.read(patientAuthApiProvider).startPhoneAuth(phone: _e164);
      if (!mounted) return;
      context.push('/otp', extra: OtpArgs(phone: _e164));
    } catch (e) {
      final humanized = _humanize(e);
      telemetry.track('welcome_start_error', {'error': humanized});
      if (!mounted) return;
      setState(() {
        _error = humanized;
        _submitting = false;
      });
    }
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('400')) {
      return "That doesn't look like a valid phone number.";
    }
    if (msg.contains('429')) {
      return 'Too many attempts — please wait a minute and try again.';
    }
    if (msg.contains('Connection') || msg.contains('SocketException')) {
      return "Couldn't reach Vedge. Check your connection and try again.";
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = theme.textTheme;
    final telemetry = ref.read(telemetryProvider);

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              VedgeSpacing.space6,
              VedgeSpacing.space6,
              VedgeSpacing.space6,
              VedgeSpacing.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandLogo(size: 32),
                    Semantics(
                      button: true,
                      label: 'Language: English. Tap to change.',
                      child: ExcludeSemantics(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(VedgeSpacing.radiusFull),
                          onTap: () {
                            telemetry.track('welcome_language_tapped');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('More languages coming soon — Twi first.'),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: VedgeSpacing.space3, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(VedgeSpacing.radiusFull),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: Text(
                              'EN',
                              style: t.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VedgeSpacing.space12),
                Semantics(
                  header: true,
                  child: Text(
                    'Your health,\none place.',
                    style: t.displayLarge,
                  ),
                ),
                const SizedBox(height: VedgeSpacing.space4),
                Text(
                  'Lab results, visits, and prescriptions from every '
                  'Vedge-connected provider, in one calm shelf.',
                  style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: VedgeSpacing.space8),
                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  const SizedBox(height: VedgeSpacing.space4),
                ],
                PhoneField(
                  controller: _phoneCtrl,
                  country: _country,
                  onCountryChanged: (c) {
                    setState(() => _country = c);
                    telemetry.track('welcome_country_changed', {'iso': c.isoCode});
                  },
                  errorText: _phoneError,
                ),
                const SizedBox(height: VedgeSpacing.space6),
                VedgeButton(
                  label: 'Get started',
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _getStarted,
                ),
                const SizedBox(height: VedgeSpacing.space6),
                Center(
                  child: Text(
                    'Built for African markets.',
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(VedgeSpacing.space3),
        decoration: BoxDecoration(
          color: VedgeColors.criticalBg,
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: VedgeColors.critical, size: 20),
            const SizedBox(width: VedgeSpacing.space2),
            Expanded(
              child: Text(message,
                  style: t.bodyMedium?.copyWith(color: VedgeColors.critical)),
            ),
          ],
        ),
      ),
    );
  }
}
