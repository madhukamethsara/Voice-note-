import 'package:go_router/go_router.dart';
import '../Screens/Student/Dashboard.dart';
import '../Screens/Login.dart';
import '../Screens/Register.dart';
import '../Screens/Roles.dart';
import '../Screens/SplashScreen.dart';
import '../Screens/Lecturer/LecturerDashboard.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/Login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/roleselect', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = (state.extra as String?) ?? 'student';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(path: '/Student/Dasboard', builder: (_, _) => const Dashboard()),
      
      
      GoRoute(
        path: '/Lecturer/Dashboard', 
        builder: (_, _) => const LecturerDashboard(),
      ),
    ],
  );
}