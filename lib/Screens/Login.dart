import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Theme/theme.dart';
import '../widgets/commonwidget.dart';
import '../Services/authservice.dart';
import '../Models/AppUser.dart';

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
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _setFieldError(String field, String msg) {
    setState(() {
      _errors[field] = msg;
      _isLoading = false;
    });
  }

  void _clearErrors() {
    setState(() {
      _errors.clear();
    });
  }

  void _routeUser(AppUser appUser) {
    _showSnack('Logged in successfully');
    if (appUser.role.toLowerCase() == 'student') {
      context.go('/Student/Dasboard');
    } else if (appUser.role.toLowerCase() == 'lecturer') {
      context.go('/Lecturer/Dashboard');
    } else {
      _showSnack('Unknown user role');
    }
  }

  Future<void> _doLogin() async {
    _clearErrors(); 

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty) return _setFieldError('email', 'Email is required');
    if (pass.isEmpty) return _setFieldError('pass', 'Password is required');

    setState(() => _isLoading = true);

    try {
      final AppUser appUser = await _authService.loginUser(
        email: email,
        password: pass,
      );

      if (!mounted) return;
      _routeUser(appUser);

    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnack(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  Future<void> _doGoogleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final AppUser appUser = await _authService.signInWithGoogle();
      if (!mounted) return;
      _routeUser(appUser);
      
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnack(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bg2,
      ),
    );
  }

  Widget _buildFieldLabel(String label, String? error) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: dmStyle(size: 11, weight: FontWeight.w500, color: AppColors.text2),
        ),
        if (error != null)
          Text(
            error,
            style: dmStyle(size: 10, weight: FontWeight.bold, color: Colors.redAccent),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(title: 'Welcome back', onBack: () => context.go('/')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Email', _errors['email']),
            const SizedBox(height: 4),
            LabeledField(
              label: '', 
              hint: 'you@university.edu',
              keyboardType: TextInputType.emailAddress,
              controller: _emailCtrl,
              onChanged: (_) => setState(() => _errors['email'] = null),
            ),
            const SizedBox(height: 12),
            
            _buildFieldLabel('Password', _errors['pass']),
            const SizedBox(height: 4),
            LabeledField(
              label: '',
              hint: 'Your password',
              obscure: true,
              controller: _passCtrl,
              onChanged: (_) => setState(() => _errors['pass'] = null),
            ),
            const SizedBox(height: 20),
            
            PrimaryButton(
              label: _isLoading ? 'Please wait...' : 'Log in',
              onTap: _isLoading ? null : _doLogin,
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
              onTap: _isLoading ? () {} : _doGoogleLogin, 
            ),
          ],
        ),
      ),
    );
  }
}