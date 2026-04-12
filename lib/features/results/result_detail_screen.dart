import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/lab_result.dart';
import 'results_screen.dart';

class ResultDetailScreen extends ConsumerWidget {
  const ResultDetailScreen({super.key, required this.resultId});
  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(labResultsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not load result: $e')),
        data: (results) {
          PatientLabResult? result;
          for (final r in results) {
            if (r.id == resultId) {
              result = r;
              break;
            }
          }
          if (result == null) {
            return const Center(child: Text('Result not found.'));
          }
          final r = result;
          final performedAt =
              r.performedAt != null ? DateTime.tryParse(r.performedAt!) : null;
          final dateLabel = performedAt != null
              ? DateFormat('d MMMM yyyy, h:mm a').format(performedAt)
              : '—';

          final (badgeText, badgeColor) = switch ((r.isCritical, r.isAbnormal)) {
            (true, _) => ('Critical', const Color(0xFFDC2626)),
            (_, true) => ('Above reference range', const Color(0xFFF59E0B)),
            _ => ('Within reference range', theme.colorScheme.primary),
          };

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(r.testName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(dateLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Result',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        '${r.value}${r.unit != null ? ' ${r.unit}' : ''}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (r.referenceRange != null)
                        Row(
                          children: [
                            Icon(Icons.straighten,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text('Reference: ${r.referenceRange}',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (r.isAbnormal) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This result is outside the reference range. '
                            'Talk to your clinician — they may want to repeat '
                            'the test or discuss next steps.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (r.notes != null && r.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Clinical notes', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(r.notes!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing flow — coming soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Share with my doctor'),
              ),
              const SizedBox(height: 16),
              Text(
                'Vedge is a records tool, not a diagnosis. Always consult '
                'your clinician before acting on a result.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
