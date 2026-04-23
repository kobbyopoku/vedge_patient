import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/patient_auth_state.dart';
import '../../core/models/patient_link.dart';
import '../../core/security/safe_url_launcher.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/provider_switcher_sheet.dart';
import '../../widgets/vedge_app_bar.dart';
import '../../widgets/vedge_button.dart';
import '../../widgets/vedge_card.dart';
import '../../widgets/vedge_pill.dart';

/// Spec §6.19 — You tab (renamed from Me).
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(patientAuthControllerProvider);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final firstName = auth.account?.firstName ?? '';
    final lastName = auth.account?.lastName ?? '';
    final initials = _initials(firstName, lastName);
    final phone = auth.account?.phone ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('you_seen');
    });

    Future<void> openLegal(String url) async {
      await launchSafeString(url);
    }

    return Scaffold(
      appBar: const VedgeAppBar(
        title: 'You',
        showProviderContext: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VedgeSpacing.space4,
            0,
            VedgeSpacing.space4,
            VedgeSpacing.space8,
          ),
          children: [
            _ProfileHeader(
              initials: initials,
              displayName: '$firstName $lastName'.trim().isEmpty
                  ? 'Vedge member'
                  : '$firstName $lastName'.trim(),
              subtitle: phone,
            ),
            const SizedBox(height: VedgeSpacing.space2),
            Align(
              alignment: Alignment.centerLeft,
              child: VedgeButton(
                label: 'Edit profile',
                variant: VedgeButtonVariant.tertiary,
                isFullWidth: false,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Editing profile lands soon.'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: VedgeSpacing.space6),

            // ── Providers ─────────────────────────────────────────
            _SectionLabel('Your providers'),
            const SizedBox(height: VedgeSpacing.space2),
            VedgeCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (auth.links.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(VedgeSpacing.space4),
                      child: Text(
                        "You haven't linked any providers yet.",
                        style: t.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    for (var i = 0; i < auth.links.length; i++) ...[
                      _ProviderRow(
                        link: auth.links[i],
                        onTap: () {
                          ref
                              .read(telemetryProvider)
                              .track('you_provider_switch');
                          showProviderSwitcherSheet(context);
                        },
                      ),
                      if (i < auth.links.length - 1)
                        Divider(
                          color: cs.outlineVariant,
                          height: 1,
                          indent: VedgeSpacing.space4,
                        ),
                    ],
                  Divider(
                    color: cs.outlineVariant,
                    height: 1,
                    indent: VedgeSpacing.space4,
                  ),
                  ListTile(
                    leading: Icon(Icons.add_rounded, color: cs.primary),
                    title: Text('Add another provider', style: t.bodyLarge),
                    onTap: () => context.push('/onboarding/find-records'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: VedgeSpacing.space6),

            // ── Notifications ─────────────────────────────────────
            _SectionLabel('Notifications'),
            const SizedBox(height: VedgeSpacing.space2),
            const _NotificationsCard(),

            const SizedBox(height: VedgeSpacing.space6),

            // ── Legal ─────────────────────────────────────────────
            _SectionLabel('Legal'),
            const SizedBox(height: VedgeSpacing.space2),
            VedgeCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _LegalRow(
                    label: 'Terms of service',
                    onTap: () =>
                        openLegal('https://vedge.health/legal/terms'),
                  ),
                  Divider(color: cs.outlineVariant, height: 1, indent: 16),
                  _LegalRow(
                    label: 'Privacy policy',
                    onTap: () =>
                        openLegal('https://vedge.health/legal/privacy'),
                  ),
                  Divider(color: cs.outlineVariant, height: 1, indent: 16),
                  ListTile(
                    title: Text('App version', style: t.bodyLarge),
                    trailing: Text('Vedge Companion 0.1.0',
                        style: t.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: VedgeSpacing.space6),
            VedgeButton(
              label: 'Sign out',
              variant: VedgeButtonVariant.destructive,
              icon: Icons.logout_rounded,
              onPressed: () => _confirmSignOut(context, ref),
            ),
            const SizedBox(height: VedgeSpacing.space4),
            Center(
              child: Text(
                'Vedge Companion v0.1.0',
                style:
                    t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    ref.read(telemetryProvider).track('you_sign_out_tapped');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in any time with your phone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(telemetryProvider).track('you_sign_out_confirmed');
      await ref.read(patientAuthControllerProvider.notifier).logout();
    }
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0] : '';
    final l = last.isNotEmpty ? last[0] : '';
    final result = (f + l).toUpperCase();
    return result.isEmpty ? '?' : result;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.displayName,
    required this.subtitle,
  });
  final String initials;
  final String displayName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: t.titleLarge?.copyWith(color: cs.onPrimary),
          ),
        ),
        const SizedBox(width: VedgeSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: t.titleLarge),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style:
                      t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: VedgeSpacing.space2),
      child: Text(
        label.toUpperCase(),
        style: t.labelMedium?.copyWith(
          color: cs.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.link, required this.onTap});
  final PatientLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        link.isCurrent
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: link.isCurrent ? cs.primary : cs.outline,
      ),
      title: Text(link.organizationName, style: t.bodyLarge),
      subtitle: link.isCurrent
          ? Text('Currently showing',
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant))
          : link.isPending
              ? const VedgePill(
                  label: 'Waiting for verification',
                  tone: VedgePillTone.caution,
                )
              : null,
    );
  }
}

class _NotificationsCard extends StatefulWidget {
  const _NotificationsCard();

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<_NotificationsCard> {
  // BACKEND-DEPENDENT — these toggles are local-only until the backend ships
  // the prefs endpoint (spec §D2). TODO: wire push_token_api preferences.
  bool _results = true;
  bool _visits = true;
  bool _refill = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return VedgeCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: _results,
            onChanged: (v) => setState(() => _results = v),
            title: const Text('Result alerts'),
            activeColor: cs.primary,
          ),
          Divider(color: cs.outlineVariant, height: 1, indent: 16),
          SwitchListTile.adaptive(
            value: _visits,
            onChanged: (v) => setState(() => _visits = v),
            title: const Text('Visit reminders'),
            activeColor: cs.primary,
          ),
          Divider(color: cs.outlineVariant, height: 1, indent: 16),
          SwitchListTile.adaptive(
            value: _refill,
            onChanged: (v) => setState(() => _refill = v),
            title: const Text('Refill ready'),
            activeColor: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      title: Text(label, style: t.bodyLarge),
      trailing:
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
    );
  }
}
