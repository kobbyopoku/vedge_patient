import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/patient_auth_state.dart';
import 'otp_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  DateTime? _dob;
  bool _termsOk = false;
  bool _showEmail = false;
  bool _submitting = false;
  String? _error;

  // Country code stub — Ghana default.
  String _countryCode = '+233';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Your date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _error = 'Please select your date of birth.');
      return;
    }
    if (!_termsOk) {
      setState(() => _error = 'Please accept the Terms to continue.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final phone = '$_countryCode${_phoneCtrl.text.trim()}';
    final dobIso = DateFormat('yyyy-MM-dd').format(_dob!);

    try {
      final authApi = ref.read(patientAuthApiProvider);
      final pending = await authApi.register(
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        dateOfBirth: dobIso,
        phone: phone,
        email:
            _showEmail && _emailCtrl.text.isNotEmpty ? _emailCtrl.text.trim() : null,
      );
      if (!mounted) return;
      context.go(
        '/otp',
        extra: OtpArgs(
          mode: OtpFlowMode.register,
          accountId: pending.accountId,
          contactType: pending.contactType,
          phoneOrEmail: phone,
        ),
      );
    } catch (e) {
      setState(() {
        _error = _humanize(e);
        _submitting = false;
      });
    }
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('409') || msg.contains('CONFLICT')) {
      return 'An account with this phone already exists. Try signing in.';
    }
    if (msg.contains('400')) return 'Please check the details and try again.';
    if (msg.contains('Connection')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create your account', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'We\'ll send a 6-digit code to confirm your phone.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],

                // Phone with country code.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 104,
                      child: DropdownButtonFormField<String>(
                        value: _countryCode,
                        decoration: const InputDecoration(labelText: 'Code'),
                        items: const [
                          DropdownMenuItem(value: '+233', child: Text('+233')),
                          DropdownMenuItem(value: '+234', child: Text('+234')),
                          DropdownMenuItem(value: '+254', child: Text('+254')),
                          DropdownMenuItem(value: '+1', child: Text('+1')),
                          DropdownMenuItem(value: '+44', child: Text('+44')),
                        ],
                        onChanged: (v) =>
                            setState(() => _countryCode = v ?? '+233'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '244 000 0000',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 7) {
                            return 'Enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstCtrl,
                  decoration: const InputDecoration(labelText: 'First name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastCtrl,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _dob == null
                          ? 'Select…'
                          : DateFormat('d MMMM yyyy').format(_dob!),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => setState(() => _showEmail = !_showEmail),
                  icon: Icon(_showEmail
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline),
                  label: Text(_showEmail ? 'Hide email' : 'Add email (optional)'),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                if (_showEmail) ...[
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                      hintText: 'you@example.com',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _termsOk,
                  onChanged: (v) => setState(() => _termsOk = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I accept Vedge\'s Terms and Privacy Policy.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
