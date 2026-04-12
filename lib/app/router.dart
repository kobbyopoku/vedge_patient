import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/patient_auth_state.dart';
import '../features/appointments/appointment_detail_screen.dart';
import '../features/appointments/appointments_screen.dart';
import '../features/claims/claims_screen.dart';
import '../features/claims/no_claims_screen.dart';
import '../features/claims/potential_matches_screen.dart';
import '../features/home/home_screen.dart';
import '../features/me/me_screen.dart';
import '../features/onboarding/login_screen.dart';
import '../features/onboarding/otp_screen.dart';
import '../features/onboarding/register_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/prescriptions/prescription_detail_screen.dart';
import '../features/prescriptions/prescriptions_screen.dart';
import '../features/results/result_detail_screen.dart';
import '../features/results/results_screen.dart';
import '../features/shell/shell_screen.dart';
import '../features/teleconsult/teleconsult_browse_screen.dart';
import '../features/teleconsult/teleconsult_join_screen.dart';
import '../features/teleconsult/teleconsult_list_screen.dart';

final patientRouterProvider = Provider<GoRouter>((ref) {
  final authListenable =
      ValueNotifier<PatientAuthState>(ref.read(patientAuthControllerProvider));
  ref.listen<PatientAuthState>(patientAuthControllerProvider, (prev, next) {
    authListenable.value = next;
  });

  const publicPaths = {
    '/welcome',
    '/register',
    '/otp',
    '/login',
  };

  const claimFlowPaths = {
    '/claims',
    '/claims/potential-matches',
    '/no-claims',
  };

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
      final isClaimFlow = claimFlowPaths.contains(location);

      // Unauthenticated → welcome/register/login only.
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
          // Allow the claim flow + me, push everything else to /no-claims.
          if (isClaimFlow || location == '/me') return null;
          return '/no-claims';
        case PatientAuthStatus.authenticatedNoCurrent:
          // Allow me (to pick a provider) and claims management.
          if (location == '/me' || isClaimFlow) return null;
          return '/me';
        case PatientAuthStatus.authenticatedReady:
          return null;
        default:
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as OtpArgs?;
          return OtpScreen(args: extra ?? const OtpArgs.empty());
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/no-claims',
        builder: (context, state) => const NoClaimsScreen(),
      ),
      GoRoute(
        path: '/claims',
        builder: (context, state) => const ClaimsScreen(),
        routes: [
          GoRoute(
            path: 'potential-matches',
            builder: (context, state) => const PotentialMatchesScreen(),
          ),
        ],
      ),
      // Teleconsult flow — rendered outside the bottom-nav shell so the
      // full-screen "Find a doctor" and "Join video room" experiences
      // don't fight with the tabbed layout. The list screen is reachable
      // from the home screen quick-action card (see home_screen.dart) and
      // from the "See your consults" action. Still gated by the
      // `authenticatedReady` state (the top-level redirect above falls
      // through for non-public paths when the user is fully logged in).
      GoRoute(
        path: '/teleconsult',
        builder: (context, state) => const TeleconsultListScreen(),
        routes: [
          GoRoute(
            path: 'browse',
            builder: (context, state) => const TeleconsultBrowseScreen(),
          ),
          GoRoute(
            path: ':sessionId/join',
            builder: (context, state) => TeleconsultJoinScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/results',
            builder: (context, state) => const ResultsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ResultDetailScreen(
                  resultId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => AppointmentDetailScreen(
                  appointmentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/prescriptions',
            builder: (context, state) => const PrescriptionsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => PrescriptionDetailScreen(
                  prescriptionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/me',
            builder: (context, state) => const MeScreen(),
          ),
        ],
      ),
    ],
  );
});

String _postAuthLanding(PatientAuthStatus s) {
  switch (s) {
    case PatientAuthStatus.authenticatedNoClaims:
      return '/no-claims';
    case PatientAuthStatus.authenticatedNoCurrent:
      return '/me';
    case PatientAuthStatus.authenticatedReady:
      return '/home';
    default:
      return '/welcome';
  }
}
