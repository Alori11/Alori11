import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/vehicles/presentation/vehicles_list_screen.dart';
import '../../features/vehicles/presentation/add_vehicle_screen.dart';
import '../../features/tracking/presentation/live_tracking_screen.dart';
import '../../features/tracking/presentation/trip_history_screen.dart';
import '../../features/devices/presentation/devices_list_screen.dart';
import '../../features/devices/presentation/device_pairing_screen.dart';
import '../../features/geofencing/presentation/geofencing_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/maintenance/presentation/add_maintenance_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

// Named route constants
class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const vehicles = '/vehicles';
  static const addVehicle = '/vehicles/add';
  static const tracking = '/tracking/:vehicleId';
  static const tripHistory = '/tracking/:vehicleId/history';
  static const devices = '/devices';
  static const pairDevice = '/devices/pair';
  static const geofencing = '/geofencing/:vehicleId';
  static const maintenance = '/maintenance/:vehicleId';
  static const addMaintenance = '/maintenance/:vehicleId/add';
  static const alerts = '/alerts';
  static const profile = '/profile';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;

      if (!onboardingDone) {
        return AppRoutes.onboarding;
      }

      final isAuth = authState.status == AuthStatus.authenticated;
      final isInitial = authState.status == AuthStatus.initial;
      final isLoading = authState.status == AuthStatus.loading;

      if (isInitial || isLoading) return null;

      final publicRoutes = [
        AppRoutes.login,
        AppRoutes.register,
        '/otp',
        AppRoutes.forgotPassword,
        AppRoutes.onboarding,
      ];

      final isPublicRoute = publicRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      if (!isAuth && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (isAuth && isPublicRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Shell route for bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ScaffoldWithBottomNav(child: child, state: state);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.vehicles,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VehiclesListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.alerts,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AlertsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addVehicle,
        builder: (context, state) => const AddVehicleScreen(),
      ),
      GoRoute(
        path: '/tracking/:vehicleId',
        builder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          return LiveTrackingScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/tracking/:vehicleId/history',
        builder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          return TripHistoryScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: AppRoutes.devices,
        builder: (context, state) => const DevicesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.pairDevice,
        builder: (context, state) => const DevicePairingScreen(),
      ),
      GoRoute(
        path: '/geofencing/:vehicleId',
        builder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          return GeofencingScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/maintenance/:vehicleId',
        builder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          return MaintenanceScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/maintenance/:vehicleId/add',
        builder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          return AddMaintenanceScreen(vehicleId: vehicleId);
        },
      ),
    ],
  );
});

class _ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const _ScaffoldWithBottomNav({required this.child, required this.state});

  int _locationIndex(String location) {
    if (location.startsWith('/vehicles')) return 1;
    if (location.startsWith('/alerts')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationIndex(state.matchedLocation);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.dashboard);
              break;
            case 1:
              context.go(AppRoutes.vehicles);
              break;
            case 2:
              context.go(AppRoutes.alerts);
              break;
            case 3:
              context.go(AppRoutes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_rounded),
            label: AppStrings.vehicles,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: AppStrings.alerts,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppStrings.profile,
          ),
        ],
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
        ),
      ),
    );
  }
}
