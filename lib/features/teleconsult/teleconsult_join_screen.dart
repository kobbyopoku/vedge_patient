import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/patient_teleconsult_api.dart';
import '../../core/models/teleconsult_session.dart';

/// Patient-side launchpad for a Daily.co video room. Route:
/// `/teleconsult/:sessionId/join`.
///
/// In v1 this screen fetches the session + join URL, then launches the
/// Daily.co room in the device browser via `url_launcher`. Full in-app
/// WebRTC (via Daily.co's Flutter SDK or `flutter_webrtc`) is a W5.6c
/// follow-up.
class TeleconsultJoinScreen extends ConsumerStatefulWidget {
  const TeleconsultJoinScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<TeleconsultJoinScreen> createState() =>
      _TeleconsultJoinScreenState();
}

class _TeleconsultJoinScreenState extends ConsumerState<TeleconsultJoinScreen> {
  bool _loading = true;
  bool _launching = false;
  TeleconsultSession? _session;
  String? _joinUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(patientTeleconsultApiProvider);
      final session = await api.getSession(widget.sessionId);
      final join = await api.getJoinUrl(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = session;
        _joinUrl = join.joinUrl.isNotEmpty ? join.joinUrl : join.roomUrl;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Couldn\'t prepare the video room. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _openRoom() async {
    final url = _joinUrl;
    if (url == null || url.isEmpty) return;
    setState(() => _launching = true);
    try {
      final uri = Uri.parse(url);
      final ok =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t open the video room.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t open: $e')),
      );
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Join video consult')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorCard(message: _error!, onRetry: _load)
                  : _buildReady(theme),
        ),
      ),
    );
  }

  Widget _buildReady(ThemeData theme) {
    final s = _session;
    final dateLabel = s != null
        ? DateFormat('EEE, d MMM • h:mm a').format(s.scheduledStart)
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.videocam_outlined,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s?.providerName ?? 'Your provider',
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
                  ],
                ),
                if (s?.reason != null && s!.reason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    s.reason!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 64,
          child: FilledButton.icon(
            onPressed: _joinUrl == null || _launching ? null : _openRoom,
            icon: _launching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.open_in_new),
            label: Text(
              _launching ? 'Opening…' : 'Open video room',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Opens in your device browser. Make sure your microphone and camera '
          'work before joining. Keep this app open so you can return here when '
          'you\'re done.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Back to consults'),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
