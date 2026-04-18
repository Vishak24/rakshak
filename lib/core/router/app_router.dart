import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/sentinel/presentation/sentinel_screen.dart';
import '../../features/alerts/presentation/alerts_stub_screen.dart';
import '../../features/map/presentation/map_stub_screen.dart';
import '../../features/user_space/presentation/user_space_screen.dart';
import '../../features/intelligence/presentation/intelligence_screen.dart';
import '../../features/intelligence/presentation/score_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import '../widgets/rk_scaffold.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // Login Screen (no shell)
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),

    // Shell Route with Bottom Navigation
    ShellRoute(
      builder: (context, state, child) {
        final currentTab = _getTabIndex(state.uri.toString());
        return RkScaffold(
          body: child,
          currentIndex: currentTab,
          onTabChanged: (index) {
            final route = _getTabRoute(index);
            context.go(route);
          },
        );
      },
      routes: [
        GoRoute(
          path: '/sentinel',
          builder: (context, state) => const SentinelScreen(),
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => const AlertsStubScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MapStubScreen(),
        ),
        GoRoute(
          path: '/user-space',
          builder: (context, state) => const UserSpaceScreen(),
        ),
      ],
    ),

    // Fullscreen Routes (no bottom nav)
    GoRoute(
      path: '/intelligence',
      builder: (context, state) => const IntelligenceScreen(),
    ),
    GoRoute(
      path: '/score',
      builder: (context, state) => const ScoreScreen(),
    ),
    GoRoute(
      path: '/sos',
      builder: (context, state) => const SosScreen(),
    ),
  ],
);

int _getTabIndex(String path) {
  if (path.contains('/sentinel')) return 0;
  if (path.contains('/alerts')) return 1;
  if (path.contains('/map')) return 2;
  if (path.contains('/user-space')) return 3;
  return 0;
}

String _getTabRoute(int index) {
  switch (index) {
    case 0:
      return '/sentinel';
    case 1:
      return '/alerts';
    case 2:
      return '/map';
    case 3:
      return '/user-space';
    default:
      return '/sentinel';
  }
}
