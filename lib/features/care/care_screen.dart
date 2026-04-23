import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/telemetry/telemetry_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/vedge_app_bar.dart';
import '../../widgets/vedge_button.dart';
import '../appointments/appointments_screen.dart';
import '../prescriptions/prescriptions_screen.dart';
import '../teleconsult/teleconsult_list_screen.dart';

/// Spec §6.11 — Care tab. Wraps Visits / Consults / Rx with chip tabs and
/// a sticky bottom CTA to book a video consult.
class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen> {
  _CareTab _active = _CareTab.visits;

  static const _tabs = [
    (_CareTab.visits, 'Visits'),
    (_CareTab.consults, 'Consults'),
    (_CareTab.rx, 'Rx'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('care_seen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const VedgeAppBar(title: 'Care'),
      body: SafeArea(
        bottom: false,
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
                            'care_tab_changed',
                            {'tab': tab.name},
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
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(VedgeSpacing.space4),
                child: VedgeButton(
                  label: 'Book a video consult',
                  icon: Icons.videocam_outlined,
                  variant: VedgeButtonVariant.secondary,
                  onPressed: () {
                    ref
                        .read(telemetryProvider)
                        .track('care_book_consult_tapped');
                    context.push('/teleconsult/browse');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyFor(_CareTab tab) {
    switch (tab) {
      case _CareTab.visits:
        return const AppointmentsScreen(embedded: true);
      case _CareTab.consults:
        return const TeleconsultListScreen(embedded: true);
      case _CareTab.rx:
        return const PrescriptionsScreen(embedded: true);
    }
  }
}

enum _CareTab { visits, consults, rx }
