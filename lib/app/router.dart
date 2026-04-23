import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/patient_auth_state.dart';
import '../core/models/patient_link.dart';
import '../features/appointments/appointment_detail_screen.dart';
import '../features/care/care_screen.dart';
import '../features/care/payment_return_screen.dart';
import '../features/family/family_screen.dart';
import '../features/onboarding/find_records_screen.dart';
import '../features/onboarding/complete_profile_screen.dart';
import '../features/onboarding/otp_screen.dart';
import '../features/onboarding/verify_link_screen.dart';
import '../features/onboarding/welcome_first_time_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/prescriptions/prescription_detail_screen.dart';
import '../features/records/records_screen.dart';
import '../features/results/result_detail_screen.dart';
import '../features/shell/shell_screen.dart';
import '../features/teleconsult/teleconsult_browse_screen.dart';
import '../features/teleconsult/teleconsult_join_screen.dart';
import '../features/today/today_screen.dart';
import '../features/you/you_screen.dart';

final patientRouterProvider = Provider<GoRouter>((ref) {
  final authListenable =
      ValueNotifier<PatientAuthState>(ref.read(patientAuthControllerProvider));
  ref.listen<PatientAuthState>(patientAuthControllerProvider, (prev, next) {
    authListenable.value = next;
  });

  // V128 phone-first flow: welcome → otp → (optionally) complete-profile.
  // /register and /login no longer exist.
  const publicPaths = {
    '/welcome',
    '/otp',
    '/complete-profile',
  };

  // Onboarding paths that an authenticated-but-no-current user can visit.
  bool isOnboardingPath(String path) =>
      path.startsWith('/onboarding/');

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = authListenable.value;
      final location = state.matchedLocation;

      if (auth.status == PatientAuthStatus.loading) {
        return null;
      }

      final isPublic = publicPaths.contains(location);
      final isOnboarding = isOnboardingPath(location);

      // Unauthenticated → welcome / otp / complete-profile only.
      if (!auth.isAuthenticated) {
        return isPublic ? null : '/welcome';
      }

      // Authenticated users should bounce out of public screens.
      if (isPublic) {
        return _postAuthLanding(auth.status);
      }

      // Auth sub-states gate access to the shell.
      switch (auth.status) {
        case PatientAuthStatus.authenticatedNoClaims:
          // New user with no tenant links yet. Previously we hard-forced
          // them into /onboarding/welcome-first and only permitted /you
          // and onboarding paths, which created a trap for users with
          // zero cross-tenant matches: find-records → continue → the
          // router rejected /today and sent them right back. Relax the
          // rule to allow the full shell — per-tab screens show empty
          // states, and /you remains the place to add NHIS / Ghana Card
          // or rerun find-records later.
          return null;
        case PatientAuthStatus.authenticatedNoCurrent:
          // Allow You (to pick a provider) and onboarding.
          if (location == '/you' || isOnboarding) return null;
          return '/you';
        case PatientAuthStatus.authenticatedReady:
          return null;
        default:
          return null;
      }
    },
    routes: [
      // ── Public auth screens ─────────────────────────────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as OtpArgs?;
          return OtpScreen(args: extra ?? const OtpArgs.empty());
        },
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) {
          final extra = state.extra as CompleteProfileArgs?;
          return CompleteProfileScreen(
            args: extra ?? const CompleteProfileArgs.empty(),
          );
        },
      ),

      // ── Onboarding (post-OTP, no-claims-yet flow) ───────────
      GoRoute(
        path: '/onboarding/welcome-first',
        builder: (context, state) => const WelcomeFirstTimeScreen(),
      ),
      GoRoute(
        path: '/onboarding/find-records',
        builder: (context, state) => const FindRecordsScreen(),
      ),
      GoRoute(
        path: '/onboarding/verify-link/:id',
        builder: (context, state) => VerifyLinkScreen(
          linkId: state.pathParameters['id']!,
          link: state.extra as PatientLink?,
        ),
      ),

      // ── Out-of-shell teleconsult routes ─────────────────────
      // Browse + join are full-screen; the list lives inside Care.
      GoRoute(
        path: '/teleconsult/browse',
        builder: (context, state) => const TeleconsultBrowseScreen(),
      ),
      GoRoute(
        path: '/teleconsult/:sessionId/join',
        builder: (context, state) => TeleconsultJoinScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      // Spec §6.16 — Paystack callback reconciliation. Reachable at
      // `/care/payment-return?ref=:ref&session=:sessionId`. Out-of-shell
      // because it deserves a focused, full-screen success / fail moment.
      GoRoute(
        path: '/care/payment-return',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['session'] ?? '';
          final ref = state.uri.queryParameters['ref'];
          return PaymentReturnScreen(sessionId: sessionId, reference: ref);
        },
      ),

      // ── Bottom-nav shell with 5 tabs ────────────────────────
      // Note: no parentNavigatorKey here. Setting it to a free-standing
      // GlobalKey that isn't attached to a live navigator caused
      // go('/you') from a non-shell onboarding route to silently fail
      // to activate the shell — GoRouter couldn't resolve which
      // navigator to mount the shell into, so no branch ever rendered.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => ShellScreen(shell: navShell),
        branches: [
          // Today
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          // Records
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/records',
                builder: (context, state) => const RecordsScreen(),
                routes: [
                  GoRoute(
                    path: 'result/:id',
                    builder: (context, state) => ResultDetailScreen(
                      resultId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Care
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/care',
                builder: (context, state) => const CareScreen(),
                routes: [
                  GoRoute(
                    path: 'visit/:id',
                    builder: (context, state) => AppointmentDetailScreen(
                      appointmentId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'rx/:id',
                    builder: (context, state) => PrescriptionDetailScreen(
                      prescriptionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Family (P1 placeholder)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/family',
                builder: (context, state) => const FamilyScreen(),
              ),
            ],
          ),
          // You
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                builder: (context, state) => const YouScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String _postAuthLanding(PatientAuthStatus s) {
  switch (s) {
    case PatientAuthStatus.authenticatedNoClaims:
      return '/onboarding/welcome-first';
    case PatientAuthStatus.authenticatedNoCurrent:
      return '/you';
    case PatientAuthStatus.authenticatedReady:
      return '/today';
    default:
      return '/welcome';
  }
}
