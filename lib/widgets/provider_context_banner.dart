import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/spacing.dart';
import 'provider_switcher_sheet.dart';
import 'vedge_button.dart';

/// Spec §5.15 — compact, dismissible banner for the *first* clinical screen
/// open in a session, when there are multiple verified providers.
///
/// Auto-dismisses after first display per day (persisted in SharedPreferences).
class ProviderContextBanner extends ConsumerStatefulWidget {
  const ProviderContextBanner({
    required this.providerName,
    super.key,
  });

  final String providerName;

  @override
  ConsumerState<ProviderContextBanner> createState() =>
      _ProviderContextBannerState();
}

class _ProviderContextBannerState extends ConsumerState<ProviderContextBanner> {
  bool _dismissed = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('vedge.provider_context_banner.last_day');
    final today = _todayKey();
    setState(() {
      _dismissed = lastShown == today;
      _checked = true;
    });
    if (lastShown != today) {
      await prefs.setString('vedge.provider_context_banner.last_day', today);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _dismissed) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VedgeSpacing.space4,
        VedgeSpacing.space2,
        VedgeSpacing.space4,
        VedgeSpacing.space2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VedgeSpacing.space3,
          vertical: VedgeSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.local_hospital_rounded,
                size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: VedgeSpacing.space2),
            Expanded(
              child: Text(
                'Showing records from ${widget.providerName}',
                style: t.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            VedgeButton(
              label: 'Switch',
              variant: VedgeButtonVariant.tertiary,
              size: VedgeButtonSize.small,
              isFullWidth: false,
              onPressed: () => showProviderSwitcherSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}
