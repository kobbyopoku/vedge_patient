import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/models/patient_link.dart';

/// Modal bottom sheet that lists all VERIFIED links with a radio to set
/// the current provider. Calls /api/patient/my/links/{id}/set-current,
/// which returns a fresh token pair that the auth controller swaps in.
class SwitchProviderSheet extends ConsumerWidget {
  const SwitchProviderSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const SwitchProviderSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(patientAuthControllerProvider);
    final theme = Theme.of(context);
    final verified =
        auth.links.where((l) => l.isVerified).toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Switch provider', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Vedge shows results and visits from one provider at a time. '
              'You can switch anytime without losing your linked records.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (verified.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No verified providers yet.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final link in verified)
                _LinkRadio(
                  link: link,
                  onSelect: () async {
                    Navigator.of(context).pop();
                    await ref
                        .read(patientAuthControllerProvider.notifier)
                        .setCurrentLink(link.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Now viewing ${link.organizationName}')),
                      );
                    }
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _LinkRadio extends StatelessWidget {
  const _LinkRadio({required this.link, required this.onSelect});
  final PatientLink link;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: link.isCurrent ? null : onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(
              link.isCurrent
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: link.isCurrent ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.organizationName,
                      style: theme.textTheme.titleMedium),
                  if (link.patientNameOnRecord != null)
                    Text('On record as ${link.patientNameOnRecord}',
                        style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
