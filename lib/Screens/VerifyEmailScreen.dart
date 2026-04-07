import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../Services/auth/authservice.dart';
import '../Theme/theme_helper.dart';
import '../widgets/commonwidget.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();

  bool _isChecking = false;
  bool _isResending = false;

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);

    try {
      final isVerified = await _authService.isEmailVerified();

      if (!mounted) return;

      if (isVerified) {
        _showSnack('Email verified successfully. Please log in.');
        await _authService.signOut();
        if (!mounted) return;
        context.go('/Login');
      } else {
        _showSnack('Your email is still not verified.');
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);

    try {
      await _authService.resendEmailVerification();
      _showSnack('Verification email sent again. Check inbox or spam.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _goToLogin() async {
    await _authService.signOut();
    if (!mounted) return;
    context.go('/Login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = _authService.currentFirebaseUser;
    final email = currentUser?.email?.trim() ?? '';

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppTopBar(
        title: 'Verify Email',
        onBack: _goToLogin,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.bg2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.bg3),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mark_email_read_rounded,
                    size: 52,
                    color: colors.teal,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Check your inbox',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification link to:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.text2,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email.isEmpty ? 'No email found. Please log in again.' : email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Open your email, click the verification link, then come back and press the button below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.text2,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isChecking ? 'Checking...' : 'I verified my email',
              onTap: _isChecking ? null : _checkVerification,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: (_isResending || email.isEmpty) ? null : _resendEmail,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.bg3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isResending ? 'Sending...' : 'Resend verification email',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: _goToLogin,
                child: Text(
                  'Back to login',
                  style: TextStyle(
                    color: colors.text2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bg2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.bg3),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: colors.teal,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For security, only verified email accounts can access the system.',
                      style: TextStyle(
                        color: colors.text2,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}