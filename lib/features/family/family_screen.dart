import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/telemetry/telemetry_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/vedge_app_bar.dart';
import '../../widgets/vedge_button.dart';
import '../../widgets/vedge_empty_state.dart';

/// Spec §6.18 — P0 placeholder. Real CRUD ships in P1.
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  bool _waitlisted = false;
  bool _loading = true;

  static const _waitlistKey = 'vedge.family.waitlisted';

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('family_placeholder_seen');
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _waitlisted = prefs.getBool(_waitlistKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _notifyMe() async {
    ref.read(telemetryProvider).track('family_notify_me_tapped');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_waitlistKey, true);
    if (!mounted) return;
    setState(() => _waitlisted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Got it — we'll let you know when Family is ready."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VedgeAppBar(
        title: 'Family',
        showProviderContext: false,
      ),
      body: _loading
          ? const SizedBox.shrink()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: VedgeSpacing.space4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VedgeEmptyState(
                      icon: Icons.diversity_3_rounded,
                      title: 'Take care of your people',
                      body:
                          "Soon: manage your kids' records, your parent's "
                          "appointments — all from here.",
                      action: _waitlisted
                          ? null
                          : VedgeButton(
                              label: 'Notify me when ready',
                              variant: VedgeButtonVariant.secondary,
                              isFullWidth: false,
                              onPressed: _notifyMe,
                            ),
                    ),
                    if (_waitlisted) ...[
                      const SizedBox(height: VedgeSpacing.space4),
                      const Icon(Icons.check_circle_outline, size: 28),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
