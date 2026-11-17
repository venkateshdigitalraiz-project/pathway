import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../storage/auth_local_storage.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/auth_register_page.dart';
import '../../features/auth/presentation/pages/auth_welcome_page.dart';
import '../../features/auth/presentation/pages/name_input_page.dart';
import '../../features/auth/presentation/pages/user_details_page.dart';
import '../../features/carpool/presentation/pages/carpool_shell_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_shell_page.dart';
import '../../features/party_booking/presentation/pages/party_shell_page.dart';
import '../../features/tour_booking/features/tour_booking/presentation/pages/tour_shell_page.dart';

/// Centralized route constants for type-safe and consistent navigation
class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String register = '/register';
  static const String nameInput = '/name-input';
  static const String userDetails = '/user-details';
  static const String carpool = '/carpool';
  static const String party = '/party';
  static const String tours = '/tours';
  static const String tour = '/tour';
  static const String main = '/';
}

/// Helper class that adapts a stream (such as a BLoC stream) to a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Central application router adhering to Clean Architecture
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Creates and configures the GoRouter instance reactive to AuthBloc
  static GoRouter createRouter(AuthBloc authBloc) {
    final bool isInitiallyAuthenticated =
        authBloc.state.status == AuthStatus.authenticated &&
        authBloc.state.user != null;

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation:
          isInitiallyAuthenticated ? AppRoutes.main : AppRoutes.welcome,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;
        final storage = AuthLocalStorage();
        final isProfileDone = storage.isProfileCompleted(authState.phoneNumber);
        final savedName =
            storage.getFullName(authState.phoneNumber)?.trim() ?? '';
        final currentName = authState.user?.fullName.trim() ?? '';
        final effectiveName = (savedName.isNotEmpty &&
                !savedName.toLowerCase().startsWith('user'))
            ? savedName
            : currentName;

        final bool hasValidFullName = effectiveName.isNotEmpty &&
            effectiveName.toLowerCase() != 'user' &&
            !effectiveName.toLowerCase().startsWith('user ') &&
            !RegExp(r'^user[\s_-]*\d*$', caseSensitive: false)
                .hasMatch(effectiveName);

        final bool profileCompleted = isProfileDone && hasValidFullName;

        final bool isAuthenticated =
            (authState.status == AuthStatus.authenticated &&
                authState.user != null) ||
            storage.isLoggedIn();
        final String location = state.matchedLocation;

        final bool isPublicAuthRoute = location == AppRoutes.welcome ||
            location == AppRoutes.register ||
            location == AppRoutes.nameInput;

        // 1. If profile is NOT completed and user logged in (first-time install):
        // Enforce redirection to UserDetailsPage!
        if (!profileCompleted &&
            (authState.status == AuthStatus.requireUserDetails ||
                isAuthenticated)) {
          if (location != AppRoutes.userDetails) {
            return AppRoutes.userDetails;
          }
          return null;
        }

        // 2. If user already completed profile and is on userDetails, redirect to main
        if (profileCompleted && location == AppRoutes.userDetails) {
          return AppRoutes.main;
        }

        // 3. If not authenticated, ensure user stays on public auth pages
        if (!isAuthenticated) {
          if (!isPublicAuthRoute && location != AppRoutes.userDetails) {
            return AppRoutes.welcome;
          }
          return null;
        }

        // 4. If authenticated and currently on welcome/register, redirect to main dashboard
        if (isAuthenticated && isPublicAuthRoute) {
          return AppRoutes.main;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.welcome,
          name: 'welcome',
          builder: (context, state) => const AuthWelcomePage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) => const AuthRegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.nameInput,
          name: 'name-input',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final email = extra['email'] as String? ?? '';
            final optOutMarketing = extra['optOutMarketing'] as bool? ?? false;
            final phoneNumber = extra['phoneNumber'] as String? ?? '';
            return NameInputPage(
              email: email,
              optOutMarketing: optOutMarketing,
              phoneNumber: phoneNumber,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.userDetails,
          name: 'user-details',
          builder: (context, state) => const UserDetailsPage(),
        ),
        GoRoute(
          path: AppRoutes.main,
          name: 'main',
          builder: (context, state) => const DashboardShellPage(),
        ),
        GoRoute(
          path: AppRoutes.carpool,
          name: 'carpool',
          builder: (context, state) => const CarpoolShellPage(),
        ),
        GoRoute(
          path: AppRoutes.party,
          name: 'party',
          builder: (context, state) => const PartyShellPage(),
        ),
        GoRoute(
          path: AppRoutes.tours,
          name: 'tours',
          builder: (context, state) => const TourShellPage(),
        ),
        GoRoute(
          path: AppRoutes.tour,
          name: 'tour',
          builder: (context, state) => const TourShellPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.uri}')),
      ),
    );
  }
}
