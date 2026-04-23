import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/models/prescription.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/vedge_button.dart';
import '../../widgets/vedge_sheet.dart';

/// Spec §6.13 — refill request sheet.
///
/// BACKEND-DEPENDENT: spec calls for a pharmacy picker (in-network list).
/// Until the backend exposes that catalog, we send the request without a
/// pharmacy id — the backend defaults to the dispensing pharmacy from the
/// original Rx. The notes field is optional.
class RefillRequestSheet extends ConsumerStatefulWidget {
  const RefillRequestSheet({required this.rx, super.key});
  final PatientPrescription rx;

  @override
  ConsumerState<RefillRequestSheet> createState() =>
      _RefillRequestSheetState();
}

class _RefillRequestSheetState extends ConsumerState<RefillRequestSheet> {
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('rx_refill_sheet_opened');
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final telemetry = ref.read(telemetryProvider);
    telemetry.track('rx_refill_submitted');
    try {
      await ref.read(patientDataApiProvider).requestRefill(
            widget.rx.id,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      telemetry.track('rx_refill_success');
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Refill requested. We'll notify you when it's ready."),
        ),
      );
    } catch (e) {
      final msg = _humanize(e);
      telemetry.track('rx_refill_error', {'error': msg});
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = msg;
      });
    }
  }

  String _humanize(Object e) {
    if (e is NoCurrentLinkException) {
      return 'Switch to the provider that prescribed this medication, then try again.';
    }
    final msg = e.toString();
    if (msg.contains('404') || msg.contains('405')) {
      return "Refills aren't enabled for this provider yet. Try again soon.";
    }
    if (msg.contains('Connection') || msg.contains('SocketException')) {
      return 'Network error. Check your connection and try again.';
    }
    return "Couldn't submit your refill. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VedgeSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.rx.medicationName,
            style: t.titleLarge,
          ),
          if (widget.rx.dose != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.rx.dose!,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: VedgeSpacing.space4),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Anything the pharmacy should know',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: VedgeSpacing.space3),
            Text(
              _error!,
              style: t.bodyMedium?.copyWith(color: cs.error),
            ),
          ],
          const SizedBox(height: VedgeSpacing.space6),
          VedgeButton(
            label: 'Send request',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

Future<void> showRefillRequestSheet(
  BuildContext context, {
  required PatientPrescription rx,
}) {
  return showVedgeSheet<void>(
    context: context,
    title: 'Request refill',
    builder: (_) => RefillRequestSheet(rx: rx),
  );
}
