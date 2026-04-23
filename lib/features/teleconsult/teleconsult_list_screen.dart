import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/patient_teleconsult_api.dart';
import '../../core/models/teleconsult_session.dart';

/// All my teleconsult sessions, split into Upcoming and Past tabs.
final _mySessionsProvider =
    FutureProvider.autoDispose<List<TeleconsultSession>>((ref) async {
  return ref.read(patientTeleconsultApiProvider).listMySessions();
});

class TeleconsultListScreen extends ConsumerStatefulWidget {
  const TeleconsultListScreen({this.embedded = false, super.key});
  final bool embedded;

  @override
  ConsumerState<TeleconsultListScreen> createState() =>
      _TeleconsultListScreenState();
}

class _TeleconsultListScreenState extends ConsumerState<TeleconsultListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_mySessionsProvider);

    final body = Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
        Expanded(
          child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          if (err is NoCurrentLinkException) {
            return const _NoCurrentCard();
          }
          return _RetryView(
            onRetry: () => ref.invalidate(_mySessionsProvider),
          );
        },
        data: (sessions) {
          final upcoming = sessions.where((s) => !s.isPast).toList()
            ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
          final past = sessions.where((s) => s.isPast).toList()
            ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_mySessionsProvider),
            child: TabBarView(
              controller: _tabController,
              children: [
                _SessionList(
                  sessions: upcoming,
                  emptyLabel:
                      'No upcoming consults. Book one to see a doctor from home.',
                  emptyIcon: Icons.videocam_outlined,
                  onCancel: _onCancel,
                ),
                _SessionList(
                  sessions: past,
                  emptyLabel: 'No past consults yet.',
                  emptyIcon: Icons.history,
                  onCancel: null,
                ),
              ],
            ),
          );
        },
          ),
        ),
      ],
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Teleconsult')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teleconsult/browse'),
        icon: const Icon(Icons.videocam_outlined),
        label: const Text('Book a consult'),
      ),
      body: body,
    );
  }

  Future<void> _onCancel(TeleconsultSession s) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _CancelDialog(session: s),
    );
    if (reason == null) return;
    try {
      await ref
          .read(patientTeleconsultApiProvider)
          .cancelSession(s.id, reason);
      if (!mounted) return;
      ref.invalidate(_mySessionsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consult cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t cancel: $e')),
      );
    }
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.sessions,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.onCancel,
  });
  final List<TeleconsultSession> sessions;
  final String emptyLabel;
  final IconData emptyIcon;
  final Future<void> Function(TeleconsultSession)? onCancel;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Icon(emptyIcon,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    emptyLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        for (final s in sessions)
          _SessionCard(session: s, onCancel: onCancel),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onCancel});
  final TeleconsultSession session;
  final Future<void> Function(TeleconsultSession)? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        DateFormat('EEE, d MMM • h:mm a').format(session.scheduledStart);
    final providerLabel = session.providerName ?? 'Provider';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.videocam_outlined,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(providerLabel,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          dateLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: session.status),
                ],
              ),
              if (session.reason != null && session.reason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  session.reason!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (session.isJoinable || session.isCancellable) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (session.isCancellable && onCancel != null)
                      TextButton(
                        onPressed: () => onCancel!(session),
                        child: const Text('Cancel'),
                      ),
                    if (session.isJoinable) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => GoRouter.of(context)
                            .push('/teleconsult/${session.id}/join'),
                        icon: const Icon(Icons.videocam),
                        label: const Text('Join now'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TeleconsultStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bg;
    final Color fg;
    switch (status) {
      case TeleconsultStatus.scheduled:
        bg = theme.colorScheme.primary.withValues(alpha: 0.14);
        fg = theme.colorScheme.primary;
        break;
      case TeleconsultStatus.active:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        fg = const Color(0xFFB45309);
        break;
      case TeleconsultStatus.completed:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case TeleconsultStatus.cancelled:
        bg = const Color(0xFFDC2626).withValues(alpha: 0.14);
        fg = const Color(0xFFB91C1C);
        break;
      case TeleconsultStatus.noShow:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case TeleconsultStatus.unknown:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.session});
  final TeleconsultSession session;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel consult?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Let the provider know why you\'re cancelling (optional).'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Cancel consult'),
        ),
      ],
    );
  }
}

class _NoCurrentCard extends StatelessWidget {
  const _NoCurrentCard();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              'Choose which provider to view from the Me tab.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => GoRouter.of(context).go('/me'),
              child: const Text('Go to Me'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text('Couldn\'t load consults',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
