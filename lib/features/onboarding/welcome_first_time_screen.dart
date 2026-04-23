import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';
import '../../core/telemetry/telemetry_service.dart';
import '../../theme/spacing.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/vedge_button.dart';

/// Spec §6.20 — first-time post-OTP welcome with reassurance copy and
/// two CTAs: find records OR skip to Today.
class WelcomeFirstTimeScreen extends ConsumerWidget {
  const WelcomeFirstTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final firstName =
        ref.watch(patientAuthControllerProvider).account?.firstName ?? 'there';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryProvider).track('welcome_first_time_seen');
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VedgeSpacing.space6,
            VedgeSpacing.space8,
            VedgeSpacing.space6,
            VedgeSpacing.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: BrandLogo(variant: BrandLogoVariant.icon, size: 80)),
              const SizedBox(height: VedgeSpacing.space6),
              Text(
                'Welcome, $firstName',
                style: t.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VedgeSpacing.space3),
              Text(
                'Your account is ready.',
                style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VedgeSpacing.space6),
              Text(
                "Now let's find your health records. We'll search Vedge "
                'providers for records that match your details.',
                style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VedgeSpacing.space4),
              Text(
                'Only you can confirm what\'s yours — nothing links '
                'automatically.',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              VedgeButton(
                label: 'Find my records',
                icon: Icons.search_rounded,
                onPressed: () {
                  ref
                      .read(telemetryProvider)
                      .track('welcome_first_time_find_records');
                  context.push('/onboarding/find-records');
                },
              ),
              const SizedBox(height: VedgeSpacing.space3),
              VedgeButton(
                label: "I'll do this later",
                variant: VedgeButtonVariant.tertiary,
                onPressed: () {
                  ref
                      .read(telemetryProvider)
                      .track('welcome_first_time_skip');
                  context.go('/today');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
