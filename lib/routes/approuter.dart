import 'package:go_router/go_router.dart';
import 'package:voicenote/Screens/Student/Dashboard.dart';
import '../Screens/Login.dart';
import '../Screens/Register.dart';
import '../Screens/Roles.dart';
import '../Screens/SplashScreen.dart';
import '../Screens/Lecture/lecturehome.dart';
import '../Screens/OnboardingScreen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/Login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/roleselect', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = (state.extra as String?) ?? 'student';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;

          return Dashboard(
            senderName: data?['senderName'] ?? 'User',
            senderRole: data?['senderRole'] ?? 'student',
          );
        },
      ),
      GoRoute(
        path: '/Lecturer/Dashboard',
        builder: (_, _) => const LecturerDashboard(),
      ),
    ],
  );
}
