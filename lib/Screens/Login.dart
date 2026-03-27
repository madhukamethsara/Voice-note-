import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Theme/theme.dart';
import '../widgets/commonwidget.dart';
import '../Services/authservice.dart';
import '../Model/AppUser.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final AuthService _authService = AuthService();

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
      final AppUser appUser = await _authService.loginUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;

      _showSnack('Logged in successfully');

      if (appUser.role.toLowerCase() == 'student') {
        context.go('/Student/Dasboard');
      } else if (appUser.role.toLowerCase() == 'lecturer') {
        context.go('/lecturer-home');
      } else {
        _showSnack('Unknown user role');
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
              onTap: _isLoading ? null : _doLogin,
            ),
            const SizedBox(height: 16),
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