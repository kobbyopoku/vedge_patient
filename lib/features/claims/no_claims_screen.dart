import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/patient_auth_state.dart';

class NoClaimsScreen extends ConsumerWidget {
  const NoClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(patientAuthControllerProvider);
    final firstName = auth.account?.firstName ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.handshake_outlined,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                'Welcome, $firstName.',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Your Vedge account is ready. Next, we\'ll check for your '
                'health records at Vedge-connected providers. You\'ll confirm '
                'each match before anything is linked to your account.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/claims/potential-matches'),
                child: const Text('Check for my records'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  // Allow skipping — they can always come back via the Me tab.
                  // We flip them into the ready state visually by letting
                  // them into /me, where they can retry anytime.
                  context.go('/me');
                },
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () =>
                      ref.read(patientAuthControllerProvider.notifier).logout(),
                  child: Text(
                    'Sign out',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
