import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Theme/theme.dart';
import '../widgets/commonwidget.dart';
import '../Services/authservice.dart';
import '../Services/userservice.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      _showSnack('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _authService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final appUser = await _userService.getUser(credential.user!.uid);

      if (!mounted) return;

      if (appUser == null) {
        _showSnack('User profile not found');
        return;
      }

      _showSnack('Logged in successfully');

      if (appUser.role == 'student') {
        context.go('/student-home');
      } else if (appUser.role == 'lecturer') {
        context.go('/lecturer-home');
      } else {
        _showSnack('Unknown user role');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showSnack('No user found for this email');
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnack('Incorrect email or password');
      } else if (e.code == 'invalid-email') {
        _showSnack('Invalid email address');
      } else {
        _showSnack('Login failed: ${e.message}');
      }
    } catch (e) {
      _showSnack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(title: 'Welcome back', onBack: () => context.pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Email',
              hint: 'you@university.edu',
              keyboardType: TextInputType.emailAddress,
              controller: _emailCtrl,
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Password',
              hint: 'Your password',
              obscure: true,
              controller: _passCtrl,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isLoading ? 'Logging in...' : 'Log in',
              onTap: _isLoading ? () {} : _doLogin,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '— or —',
                style: dmStyle(size: 11, color: AppColors.text3),
              ),
            ),
            const SizedBox(height: 10),
            OutlineButton2(
              label: '🔵  Continue with Google',
              onTap: () {
                _showSnack('Google login not implemented yet');
              },
            ),
          ],
        ),
      ),
    );
  }
}
