import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/commonwidget.dart';
import '../Services/auth/authservice.dart';
import '../Services/onboardingservice.dart';
import '../Models/AppUser.dart';
import '../Theme/theme_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  final AuthService _authService = AuthService();
  final OnboardingService _onboardingService = OnboardingService();

  bool _isLoading = false;
  bool _showPasswordStep = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email.trim());
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _goToPasswordStep() {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showSnack('Please enter your email');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }

    setState(() {
      _showPasswordStep = true;
    });
  }

  Future<void> _doLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty) {
      _showSnack('Please enter your email');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      _showSnack('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AppUser appUser = await _authService.loginUser(
        email: email,
        password: password,
      );

      final bool isVerified = await _authService.isEmailVerified();

      if (!mounted) return;

      if (!isVerified) {
        _showSnack('Please verify your email before logging in.');

        // IMPORTANT:
        // Do NOT sign out here.
        // Keep the Firebase user session so VerifyEmailScreen
        // can read the real email and resend verification.
        context.go('/verify-email');
        return;
      }

      final bool seenOnboarding = await _onboardingService.hasSeenOnboarding();

      if (!mounted) return;

      _showSnack('Logged in successfully');

      if (!seenOnboarding) {
        context.go('/onboarding');
        return;
      }

      final role = appUser.role.toLowerCase().trim();

      if (role == 'student') {
        context.go('/dashboard');
      } else if (role == 'lecturer') {
        context.go('/lecture');
      } else {
        _showSnack('Unknown user role');
        await _authService.signOut();
        if (!mounted) return;
        context.go('/Login');
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnack(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _backToEmailStep() {
    setState(() {
      _showPasswordStep = false;
      _passCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppTopBar(
        title: _showPasswordStep ? 'Enter password' : 'Welcome back',
        onBack: () {
          if (_showPasswordStep) {
            _backToEmailStep();
          } else {
            context.go('/');
          }
        },
      ),
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
            if (_showPasswordStep) ...[
              LabeledField(
                label: 'Password',
                hint: 'Your password',
                obscure: true,
                controller: _passCtrl,
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${_emailCtrl.text.trim()}',
                style: TextStyle(color: colors.text3, fontSize: 11),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isLoading
                  ? (_showPasswordStep ? 'Logging in...' : 'Checking...')
                  : (_showPasswordStep ? 'Log in' : 'Continue'),
              onTap: _isLoading
                  ? null
                  : (_showPasswordStep ? _doLogin : _goToPasswordStep),
            ),
            const SizedBox(height: 16),
            if (_showPasswordStep)
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _backToEmailStep,
                  child: Text(
                    'Change email',
                    style: TextStyle(
                      color: colors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (!_showPasswordStep) ...[
              Center(
                child: Text(
                  '— or —',
                  style: TextStyle(color: colors.text3, fontSize: 11),
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
          ],
        ),
      ),
    );
  }
}
