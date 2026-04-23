import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/models/lab_result.dart';

final labResultsProvider =
    FutureProvider.autoDispose<List<PatientLabResult>>((ref) async {
  return ref.read(patientDataApiProvider).getLabResults();
});

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({this.embedded = false, super.key});
  final bool embedded;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(labResultsProvider);
    final body = Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Flagged'),
          ],
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorView(err: err, onRetry: () {
              ref.invalidate(labResultsProvider);
            }),
            data: (results) {
              final abnormal = results.where((r) => r.isAbnormal).toList();
              return TabBarView(
                controller: _tab,
                children: [
                  _ResultsList(results: results),
                  _ResultsList(results: abnormal),
                ],
              );
            },
          ),
        ),
      ],
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Lab results')),
      body: body,
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});
  final List<PatientLabResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const _EmptyState(
        icon: Icons.science_outlined,
        title: 'No results yet',
        body:
            'When your current provider releases a lab result, it\'ll appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _ResultTile(result: results[i]),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});
  final PatientLabResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final performedAt = result.performedAt != null
        ? DateTime.tryParse(result.performedAt!)
        : null;
    final dateLabel = performedAt != null
        ? DateFormat('d MMM yyyy').format(performedAt)
        : '—';

    final (badgeText, badgeColor) = switch ((
      result.isCritical,
      result.isAbnormal,
    )) {
      (true, _) => ('Critical', const Color(0xFFDC2626)),
      (_, true) => ('Flagged', const Color(0xFFF59E0B)),
      _ => ('Normal', cs.primary),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/records/result/${result.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.testName, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '$dateLabel • ${result.value}${result.unit != null ? ' ${result.unit}' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.err, required this.onRetry});
  final Object err;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (err is NoCurrentLinkException) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('Pick a current provider',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'To see your results, choose which provider to view from the '
                'Me tab.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/you'),
                child: const Text('Go to You'),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text('Couldn\'t load results', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
