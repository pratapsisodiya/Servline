import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servline/providers/auth_provider.dart';
import 'package:servline/screens/auth/login_screen.dart';
import 'package:servline/screens/auth/signup_screen.dart';
import 'package:servline/screens/auth/forgot_password_screen.dart';
import 'package:servline/screens/feedback/feedback_screen.dart';
import 'package:servline/screens/home/home_screen.dart';
import 'package:servline/screens/history/visit_history_screen.dart';
import 'package:servline/screens/location/nearby_locations_screen.dart';
import 'package:servline/screens/notifications/notifications_screen.dart';
import 'package:servline/screens/onboarding/how_it_works_screen.dart';
import 'package:servline/screens/onboarding/location_access_screen.dart';
import 'package:servline/screens/onboarding/notification_access_screen.dart';
import 'package:servline/screens/onboarding/welcome_intro_screen.dart';
import 'package:servline/screens/service/select_service_screen.dart';
import 'package:servline/screens/settings/settings_screen.dart';
import 'package:servline/screens/profile/profile_screen.dart';
import 'package:servline/screens/support/help_center_screen.dart';
import 'package:servline/screens/splash_screen.dart';
import 'package:servline/screens/ticket/active_ticket_screen.dart';
import 'package:servline/screens/ticket/your_turn_screen.dart';
import 'package:servline/screens/qr/qr_scanner_screen.dart';
import 'package:servline/screens/appointment/schedule_appointment_screen.dart';
import 'package:servline/screens/admin/admin_dashboard_screen.dart';
import 'package:servline/screens/admin/admin_signup_screen.dart';
import 'package:servline/screens/admin/queue_operator_screen.dart';
import 'package:servline/screens/admin/services_screen.dart';
import 'package:servline/screens/admin/venue_form_screen.dart';
import 'package:servline/screens/admin/venue_qr_screen.dart';
import 'package:servline/screens/main_layout.dart';
import 'package:servline/screens/queue/register_queue_screen.dart';

import 'package:servline/providers/ticket_provider.dart';

/// Routes that don't require authentication
const _publicRoutes = [
  '/',
  '/intro',
  '/how-it-works',
  '/notification-access',
  '/location-access',
  '/login',
  '/signup',
  '/forgot-password',
  '/admin/signup',
];

/// Create router with optional authentication redirect
GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isAdmin = ref.read(isAdminProvider);
      final currentPath = state.matchedLocation;

      // Allow public routes without authentication
      if (_publicRoutes.contains(currentPath)) {
        return null;
      }

      // Redirect to login if not authenticated
      if (!isLoggedIn) {
        return '/login';
      }

      // Guard admin routes — non-admins get bounced to home
      if (currentPath.startsWith('/admin') && !isAdmin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const WelcomeIntroScreen(),
      ),
      GoRoute(
        path: '/how-it-works',
        builder: (context, state) => const HowItWorksScreen(),
      ),
      GoRoute(
        path: '/notification-access',
        builder: (context, state) => const NotificationAccessScreen(),
      ),
      GoRoute(
        path: '/location-access',
        builder: (context, state) => const LocationAccessScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'nearby',
                    builder: (context, state) => const NearbyLocationsScreen(),
                  ),
                  GoRoute(
                    path: 'select-service/:locationId',
                    builder: (context, state) {
                      final locationId =
                          state.pathParameters['locationId'] ?? '';
                      return SelectServiceScreen(locationId: locationId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/active-ticket',
                builder: (context, state) => const ActiveTicketScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const VisitHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // New routes for Appwrite integration
      GoRoute(
        path: '/scan-qr',
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: '/register-queue',
        builder: (context, state) => const RegisterQueueScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/feedback/:ticketId/:locationId',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId'] ?? '';
          final locationId = state.pathParameters['locationId'] ?? '';
          return FeedbackScreen(ticketId: ticketId, locationId: locationId);
        },
      ),
      GoRoute(
        path: '/your-turn',
        builder: (context, state) => const YourTurnScreen(),
      ),
      GoRoute(
        path:
            '/schedule-appointment/:locationId/:locationName/:serviceId/:serviceName',
        builder: (context, state) {
          final locationId = state.pathParameters['locationId'] ?? '';
          final locationName = state.pathParameters['locationName'] ?? '';
          final serviceId = state.pathParameters['serviceId'] ?? '';
          final serviceName = state.pathParameters['serviceName'] ?? '';
          return ScheduleAppointmentScreen(
            locationId: locationId,
            locationName: locationName,
            serviceId: serviceId,
            serviceName: serviceName,
          );
        },
      ),

      // ── Admin routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/signup',
        builder: (context, state) => const AdminSignupScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/venue/new',
        builder: (context, state) => const VenueFormScreen(),
      ),
      GoRoute(
        path: '/admin/venue/:id/edit',
        builder: (context, state) {
          final location = state.extra as dynamic;
          return VenueFormScreen(location: location);
        },
      ),
      GoRoute(
        path: '/admin/venue/:id/qr',
        builder: (context, state) {
          final location = state.extra as dynamic;
          return VenueQrScreen(location: location);
        },
      ),
      GoRoute(
        path: '/admin/venue/:id/services',
        builder: (context, state) {
          final location = state.extra as dynamic;
          return ServicesScreen(location: location);
        },
      ),
      GoRoute(
        path: '/admin/venue/:id/operate',
        builder: (context, state) {
          final location = state.extra as dynamic;
          return QueueOperatorScreen(location: location);
        },
      ),
    ],
  );
}
