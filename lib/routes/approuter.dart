import 'package:go_router/go_router.dart';
import '../Screens/Login.dart';
import '../Screens/Register.dart';
import '../Screens/Roles.dart';
import '../Screens/SplashScreen.dart';
import '../Screens/lecturehame.dart';
import '../Screens/studenthome.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/Login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/roleselect',
        builder: (_, __) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = (state.extra as String?) ?? 'student';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(
        path: '/student-home',
        builder: (_, __) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/lecturer-home',
        builder: (_, __) => const LecturerHomeScreen(),
      ),
    ],
  );
}