import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/models/patient_link.dart';

class PotentialMatchesScreen extends ConsumerStatefulWidget {
  const PotentialMatchesScreen({super.key});

  @override
  ConsumerState<PotentialMatchesScreen> createState() =>
      _PotentialMatchesScreenState();
}

class _PotentialMatchesScreenState
    extends ConsumerState<PotentialMatchesScreen> {
  bool _loading = true;
  String? _error;
  List<PatientLink> _matches = const [];

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(patientClaimsApiProvider);
      final results = await api.potentialMatches();
      // Also pull full links list so we can show any PENDING ones already
      // created by a prior run.
      final all = await api.getLinks();
      final pending = [
        ...results,
        ...all.where(
          (l) =>
              l.isPending && !results.any((r) => r.id == l.id),
        ),
      ];
      setState(() {
        _matches = pending;
        _loading = false;
      });
      // Also refresh the auth controller's view so the Claims screen shows
      // any newly discovered pending links.
      // ignore: unawaited_futures
      ref.read(patientAuthControllerProvider.notifier).refreshLinks();
    } catch (e) {
      setState(() {
        _error = 'Could not run the match scan. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _confirm(PatientLink link) async {
    try {
      await ref.read(patientClaimsApiProvider).confirm(link.id);
      await ref.read(patientAuthControllerProvider.notifier).refreshLinks();
      setState(() {
        _matches = _matches.where((m) => m.id != link.id).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Linked to ${link.organizationName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not confirm. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(patientAuthControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find your records'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (auth.status == PatientAuthStatus.authenticatedNoClaims) {
              context.go('/no-claims');
            } else {
              context.go('/claims');
            }
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _scan,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'We can search Vedge-connected providers for records matching '
              'your name, phone, and date of birth. Only you can confirm which '
              'records are yours.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_error!, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _scan,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_matches.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.search_off_outlined,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('No matches found',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'We couldn\'t find records matching your details. '
                        'If you think this is wrong, contact the provider '
                        'who sees you and ask them to update your profile.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _scan,
                        child: const Text('Rescan'),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final m in _matches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.organizationName,
                              style: theme.textTheme.titleMedium),
                          if (m.patientNameOnRecord != null) ...[
                            const SizedBox(height: 4),
                            Text('On record as ${m.patientNameOnRecord}',
                                style: theme.textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _confirm(m),
                                  child: const Text('Confirm this is me'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
