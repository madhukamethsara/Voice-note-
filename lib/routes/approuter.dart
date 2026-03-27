import 'package:go_router/go_router.dart';
import '../Screens/Login.dart';
import '../Screens/Register.dart';
import '../Screens/Roles.dart';
import '../Screens/SplashScreen.dart';
import '../Screens/Lecture/lecturehome.dart';
import '../Screens/Student/studenthome.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/Login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/roleselect',
        builder: (_, _) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = (state.extra as String?) ?? 'student';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(
        path: '/Student/student-home',
        builder: (_, _) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/lecturer-home',
        builder: (_, _) => const LecturerHomeScreen(),
      ),
    ],
  );
}