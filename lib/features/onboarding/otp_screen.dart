import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';

enum OtpFlowMode { register, login }

class OtpArgs {
  final OtpFlowMode mode;
  final String? accountId; // only used for register flow
  final String contactType;
  final String phoneOrEmail;

  const OtpArgs({
    required this.mode,
    required this.contactType,
    required this.phoneOrEmail,
    this.accountId,
  });

  const OtpArgs.empty()
      : mode = OtpFlowMode.login,
        accountId = null,
        contactType = 'PHONE',
        phoneOrEmail = '';
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});
  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _cellCount = 6;
  late final List<TextEditingController> _cells;
  late final List<FocusNode> _focusNodes;
  bool _submitting = false;
  String? _error;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cells = List.generate(_cellCount, (_) => TextEditingController());
    _focusNodes = List.generate(_cellCount, (_) => FocusNode());
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendIn > 0) _resendIn -= 1;
        if (_resendIn == 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    for (final c in _cells) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String _code() => _cells.map((c) => c.text).join();

  void _onCellChanged(int index, String value) {
    if (value.isNotEmpty && index < _cellCount - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code().length == _cellCount && !_submitting) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final code = _code();
    if (code.length != _cellCount) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final controller = ref.read(patientAuthControllerProvider.notifier);
      final authApi = ref.read(patientAuthApiProvider);

      final token = widget.args.mode == OtpFlowMode.register
          ? await authApi.verifyRegisterOtp(
              accountId: widget.args.accountId!,
              code: code,
              contactType: widget.args.contactType,
            )
          : await authApi.verifyLoginOtp(
              phoneOrEmail: widget.args.phoneOrEmail,
              code: code,
            );

      await controller.applyTokenResponse(token);
      // Router redirect will take us from here based on auth state.
      if (mounted) {
        // No explicit navigation — the listener in router reacts.
      }
    } catch (e) {
      setState(() {
        _error = _humanize(e);
        _submitting = false;
        for (final c in _cells) {
          c.clear();
        }
      });
      _focusNodes.first.requestFocus();
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    try {
      if (widget.args.mode == OtpFlowMode.login) {
        await ref
            .read(patientAuthApiProvider)
            .requestLoginOtp(phoneOrEmail: widget.args.phoneOrEmail);
      } else {
        // For register, request a fresh login-otp against the same contact —
        // the backend's verify-otp endpoint also accepts codes generated here
        // once the account exists. We fall back to login-otp after register.
        await ref
            .read(patientAuthApiProvider)
            .requestLoginOtp(phoneOrEmail: widget.args.phoneOrEmail);
      }
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code sent.')),
        );
      }
    } catch (e) {
      setState(() => _error = _humanize(e));
    }
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('400') || msg.contains('401')) {
      return 'That code didn\'t match. Try again.';
    }
    if (msg.contains('Connection')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sent = widget.args.phoneOrEmail.isNotEmpty
        ? widget.args.phoneOrEmail
        : 'your phone';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.args.mode == OtpFlowMode.register) {
              context.go('/register');
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Check your messages', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: sent,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i < _cellCount; i++)
                    _OtpCell(
                      controller: _cells[i],
                      focusNode: _focusNodes[i],
                      onChanged: (v) => _onCellChanged(i, v),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: _resendIn > 0
                    ? Text(
                        'Resend code in $_resendIn s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: Text(
                          'Resend code',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const Spacer(),
              if (_submitting)
                const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 64,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
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
