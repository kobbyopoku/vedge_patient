import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/telemetry/telemetry_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/vedge_app_bar.dart';
import '../results/results_screen.dart';

/// Spec §6.9 — Records tab. Wraps the existing results screen with chip
/// tabs (All / Labs / Imaging / Docs / Insurance). Imaging / Docs /
/// Insurance are P1 placeholders; Labs is the live one.
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  _RecordsTab _active = _RecordsTab.labs;

  static const _tabs = [
    (_RecordsTab.all, 'All'),
    (_RecordsTab.labs, 'Labs'),
    (_RecordsTab.imaging, 'Imaging'),
    (_RecordsTab.docs, 'Docs'),
    (_RecordsTab.insurance, 'Insurance'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('records_seen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const VedgeAppBar(title: 'Records'),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: VedgeSpacing.space4,
                ),
                children: [
                  for (final (tab, label) in _tabs) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: VedgeSpacing.space2),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _active == tab,
                        onSelected: (_) {
                          setState(() => _active = tab);
                          ref.read(telemetryProvider).track(
                            'records_tab_changed',
                            {'category': tab.name},
                          );
                        },
                        backgroundColor: cs.surfaceContainerHighest,
                        selectedColor: cs.primary,
                        labelStyle: TextStyle(
                          color: _active == tab
                              ? cs.onPrimary
                              : cs.onSurface,
                        ),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _bodyFor(_active),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyFor(_RecordsTab tab) {
    switch (tab) {
      case _RecordsTab.all:
      case _RecordsTab.labs:
        // Labs is the only live category in v1 (results screen).
        return const ResultsScreen(embedded: true);
      case _RecordsTab.imaging:
        return _ComingSoon(label: 'Imaging reports');
      case _RecordsTab.docs:
        return _ComingSoon(label: 'Documents');
      case _RecordsTab.insurance:
        return _ComingSoon(label: 'Insurance card');
    }
  }
}

enum _RecordsTab { all, labs, imaging, docs, insurance }

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VedgeSpacing.space6),
        child: Text(
          '$label arrive in a future update.',
          style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
