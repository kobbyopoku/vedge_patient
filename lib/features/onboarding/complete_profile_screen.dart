import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/security/safe_url_launcher.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/date_field.dart';
import '../../widgets/vedge_app_bar.dart';
import '../../widgets/vedge_button.dart';

/// Arguments passed to [CompleteProfileScreen] after /verify-start returns
/// [VerifyStartPendingRegistration]. The phone is already verified at this
/// point — we only need profile fields + the registration JWT to redeem.
class CompleteProfileArgs {
  const CompleteProfileArgs({
    required this.phone,
    required this.registrationToken,
    required this.expiresInSeconds,
  });
  const CompleteProfileArgs.empty()
      : phone = '',
        registrationToken = '',
        expiresInSeconds = 0;

  final String phone;
  final String registrationToken;
  final int expiresInSeconds;
}

/// V128 step 3: finish signup for a brand-new phone.
///
/// Collects first name, last name, DOB, and terms consent, then POSTs
/// /api/patient/auth/complete-registration to create the account (phone
/// already verified server-side at step 2).
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({required this.args, super.key});
  final CompleteProfileArgs args;

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _nhisCtrl = TextEditingController();
  final _ghanaCardCtrl = TextEditingController();
  DateTime? _dob;
  bool _termsOk = false;
  bool _submitting = false;
  String? _error;
  String? _dobError;

  static final Uri _termsUrl = Uri.parse('https://vedge.health/legal/terms');
  static final Uri _privacyUrl =
      Uri.parse('https://vedge.health/legal/privacy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('complete_profile_seen');
    });
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _nhisCtrl.dispose();
    _ghanaCardCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_firstCtrl.text.trim().isEmpty) return false;
    if (_lastCtrl.text.trim().isEmpty) return false;
    if (_dob == null) return false;
    if (!_termsOk) return false;
    return true;
  }

  Future<void> _openLink(Uri url) async {
    final ok = await launchSafe(url);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open — please try again.")),
      );
    }
  }

  Future<void> _submit() async {
    setState(() {
      _dobError = null;
      _error = null;
    });

    if (_dob == null) {
      setState(() => _dobError = 'Select your date of birth');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final telemetry = ref.read(telemetryProvider);
    telemetry.track('complete_profile_submit_attempt');

    setState(() => _submitting = true);

    final dobIso = DateFormat('yyyy-MM-dd').format(_dob!);

    try {
      final tokens =
          await ref.read(patientAuthApiProvider).completeRegistration(
                registrationToken: widget.args.registrationToken,
                firstName: _firstCtrl.text.trim(),
                lastName: _lastCtrl.text.trim(),
                dateOfBirth: dobIso,
                nhisNumber: _nhisCtrl.text.trim().isEmpty
                    ? null
                    : _nhisCtrl.text.trim(),
                nationalId: _ghanaCardCtrl.text.trim().isEmpty
                    ? null
                    : _ghanaCardCtrl.text.trim(),
              );
      telemetry.track('complete_profile_submit_success');
      await ref
          .read(patientAuthControllerProvider.notifier)
          .applyTokenResponse(tokens);
      // Auth-state listener routes us out.
    } catch (e) {
      final humanized = _humanize(e);
      telemetry.track('complete_profile_submit_error',
          {'error_message': humanized});
      if (!mounted) return;
      setState(() {
        _error = humanized;
        _submitting = false;
      });
    }
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('409') || msg.contains('CONFLICT')) {
      return 'This phone is already registered. Go back and try signing in.';
    }
    if (msg.contains('401')) {
      return 'This signup session expired. Please start again from the phone screen.';
    }
    if (msg.contains('400')) {
      return 'Please check the details and try again.';
    }
    if (msg.contains('Connection') || msg.contains('SocketException')) {
      return "Couldn't reach Vedge. Check your connection and try again.";
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const VedgeAppBar(
        title: 'Create account',
        showBack: true,
        showProviderContext: false,
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              VedgeSpacing.space6,
              0,
              VedgeSpacing.space6,
              VedgeSpacing.space8,
            ),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(
                    TextSpan(
                      style:
                          t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                      children: [
                        const TextSpan(text: 'Signing up with '),
                        TextSpan(
                          text: widget.args.phone,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                            text: '. A couple more details and you\'re in.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: VedgeSpacing.space6),
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!),
                    const SizedBox(height: VedgeSpacing.space4),
                  ],
                  TextFormField(
                    controller: _firstCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.givenName],
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: VedgeSpacing.space3),
                  TextFormField(
                    controller: _lastCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.familyName],
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: VedgeSpacing.space3),
                  DateField(
                    label: 'Date of birth',
                    value: _dob,
                    errorText: _dobError,
                    onChanged: (d) => setState(() => _dob = d),
                  ),
                  const SizedBox(height: VedgeSpacing.space5),
                  _IdsExplainer(),
                  const SizedBox(height: VedgeSpacing.space3),
                  TextFormField(
                    controller: _nhisCtrl,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'NHIS number (optional)',
                      hintText: 'From your NHIS card',
                    ),
                  ),
                  const SizedBox(height: VedgeSpacing.space3),
                  TextFormField(
                    controller: _ghanaCardCtrl,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Ghana Card number (optional)',
                      hintText: 'GHA-XXXXXXXXX-X',
                    ),
                  ),
                  const SizedBox(height: VedgeSpacing.space4),
                  _TermsCheckbox(
                    value: _termsOk,
                    onChanged: (v) {
                      setState(() => _termsOk = v);
                      if (v) {
                        ref
                            .read(telemetryProvider)
                            .track('complete_profile_terms_accepted');
                      }
                    },
                    onTermsTap: () => _openLink(_termsUrl),
                    onPrivacyTap: () => _openLink(_privacyUrl),
                  ),
                  const SizedBox(height: VedgeSpacing.space6),
                  VedgeButton(
                    label: 'Create account',
                    isLoading: _submitting,
                    onPressed: _isValid && !_submitting ? _submit : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdsExplainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(VedgeSpacing.space3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: cs.primary),
          const SizedBox(width: VedgeSpacing.space2),
          Expanded(
            child: Text(
              'Add one of these so we can safely link your records from '
              "clinics you've visited. We won't share these — they just "
              "prove it's really you.",
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(VedgeSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Semantics(
                checked: value,
                label: 'I agree to the terms and privacy policy',
                child: ExcludeSemantics(
                  child: Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                    activeColor: cs.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
            const SizedBox(width: VedgeSpacing.space2),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: t.bodyMedium?.copyWith(color: cs.onSurface),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: InkWell(
                        onTap: onTermsTap,
                        child: Text(
                          'Terms',
                          style: t.bodyMedium?.copyWith(
                            color: cs.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: InkWell(
                        onTap: onPrivacyTap,
                        child: Text(
                          'Privacy Policy',
                          style: t.bodyMedium?.copyWith(
                            color: cs.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
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
                  style: t.bodyMedium
                      ?.copyWith(color: VedgeColors.critical)),
            ),
          ],
        ),
      ),
    );
  }
}
