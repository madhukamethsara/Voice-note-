import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../Services/auth/authservice.dart';
import '../Theme/theme_helper.dart';
import '../widgets/commonwidget.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final TextEditingController _universityCtrl = TextEditingController();
  final TextEditingController _degreeCtrl = TextEditingController();
  final TextEditingController _yearOfStudyCtrl = TextEditingController();
  final TextEditingController _departmentCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _passwordStrength = 0;
  Color _strengthColor = Colors.red;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_handlePasswordChanged);
    _confirmPasswordCtrl.addListener(_handleConfirmPasswordChanged);
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_handlePasswordChanged);
    _confirmPasswordCtrl.removeListener(_handleConfirmPasswordChanged);

    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _universityCtrl.dispose();
    _degreeCtrl.dispose();
    _yearOfStudyCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  bool get _isStudent => widget.role.toLowerCase() == 'student';
  bool get _isLecturer => widget.role.toLowerCase() == 'lecturer';

  bool get _passwordsMatch =>
      _confirmPasswordCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _confirmPasswordCtrl.text;

  bool get _canRegister => _passwordStrength >= 3;

  void _handlePasswordChanged() {
    _checkPasswordStrength(_passwordCtrl.text);
  }

  void _handleConfirmPasswordChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email.trim());
  }

  bool _isStrongPassword(String password) {
    return _passwordStrength >= 3;
  }

  void _checkPasswordStrength(String password) {
    int score = 0;

    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar =
        RegExp(r"""[!@#$%^&*(),.?":{}|<>_\-\\/[\]=+;'`~]""")
            .hasMatch(password);

    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasNumber) score++;
    if (hasSpecialChar) score++;

    if (!mounted) return;

    setState(() {
      _hasMinLength = hasMinLength;
      _hasUppercase = hasUppercase;
      _hasLowercase = hasLowercase;
      _hasNumber = hasNumber;
      _hasSpecialChar = hasSpecialChar;
      _passwordStrength = score;

      if (score <= 2) {
        _strengthColor = Colors.red;
      } else if (score <= 4) {
        _strengthColor = Colors.orange;
      } else {
        _strengthColor = Colors.green;
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _doRegister() async {
    final fullName = _fullNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();
    final university = _universityCtrl.text.trim();
    final degree = _degreeCtrl.text.trim();
    final yearOfStudy = _yearOfStudyCtrl.text.trim();
    final department = _departmentCtrl.text.trim();

    if (fullName.isEmpty) {
      _showSnack('Please enter your full name');
      return;
    }

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

    if (!_isStrongPassword(password)) {
      _showSnack(
        'Password is too weak. Use at least 8 characters with uppercase, lowercase, number, and symbol.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showSnack('Please confirm your password');
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Passwords do not match');
      return;
    }

    if (university.isEmpty) {
      _showSnack('Please enter your university');
      return;
    }

    if (_isStudent) {
      if (degree.isEmpty) {
        _showSnack('Please enter your degree');
        return;
      }

      if (yearOfStudy.isEmpty) {
        _showSnack('Please enter your year of study');
        return;
      }
    }

    if (_isLecturer) {
      if (department.isEmpty) {
        _showSnack('Please enter your department');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerUser(
        fullName: fullName,
        email: email,
        password: password,
        role: widget.role,
        university: university,
        degree: _isStudent ? degree : null,
        yearOfStudy: _isStudent ? yearOfStudy : null,
        department: _isLecturer ? department : null,
      );

      if (!mounted) return;

      _showSnack('Account created. Please verify your email.');
      context.go('/verify-email');
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnack(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRoleBadge(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.teal.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isStudent ? Icons.school_rounded : Icons.badge_rounded,
            color: colors.teal,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _isStudent ? 'Register as Student' : 'Register as Lecturer',
            style: TextStyle(
              color: colors.teal,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCheck({
    required BuildContext context,
    required String text,
    required bool isValid,
  }) {
    final colors = context.colors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isValid
            ? Colors.green.withOpacity(0.10)
            : colors.bg2.withOpacity(0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isValid
              ? Colors.green.withOpacity(0.40)
              : colors.bg3.withOpacity(0.90),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isValid ? Icons.check_rounded : Icons.close_rounded,
              key: ValueKey(isValid),
              size: 14,
              color: isValid ? Colors.green : colors.text2,
            ),
          ),
          const SizedBox(width: 5),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color: isValid ? Colors.green : colors.text2,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            color: colors.text2,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: colors.bg2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _strengthColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _strengthColor.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            onChanged: (value) {
              _checkPasswordStrength(value);
            },
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: colors.teal,
            decoration: InputDecoration(
              hintText: 'Create a strong password',
              hintStyle: TextStyle(
                color: colors.text2.withOpacity(0.75),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: colors.text2,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _passwordStrength / 5),
            duration: const Duration(milliseconds: 220),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: colors.bg3,
                valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildMiniCheck(
              context: context,
              text: '8+',
              isValid: _hasMinLength,
            ),
            _buildMiniCheck(
              context: context,
              text: 'A-Z',
              isValid: _hasUppercase,
            ),
            _buildMiniCheck(
              context: context,
              text: 'a-z',
              isValid: _hasLowercase,
            ),
            _buildMiniCheck(
              context: context,
              text: '0-9',
              isValid: _hasNumber,
            ),
            _buildMiniCheck(
              context: context,
              text: '@#',
              isValid: _hasSpecialChar,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField(BuildContext context) {
    final colors = context.colors;
    final bool hasText = _confirmPasswordCtrl.text.isNotEmpty;
    final bool isMatch = _passwordsMatch;

    Color borderColor;
    if (!hasText) {
      borderColor = colors.bg3;
    } else if (isMatch) {
      borderColor = Colors.green;
    } else {
      borderColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: TextStyle(
            color: colors.text2,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: colors.bg2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: TextField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscureConfirmPassword,
            onChanged: (_) {
              setState(() {});
            },
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: colors.teal,
            decoration: InputDecoration(
              hintText: 'Re-enter your password',
              hintStyle: TextStyle(
                color: colors.text2.withOpacity(0.75),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasText)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        isMatch
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        key: ValueKey(isMatch),
                        color: isMatch ? Colors.green : Colors.red,
                        size: 19,
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: colors.text2,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppTopBar(
        title: 'Create account',
        onBack: () => context.go('/roleselect'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoleBadge(context),
            const SizedBox(height: 18),

            LabeledField(
              label: 'Full Name',
              hint: 'Enter your full name',
              controller: _fullNameCtrl,
            ),
            const SizedBox(height: 12),

            LabeledField(
              label: 'Email',
              hint: 'you@university.edu',
              keyboardType: TextInputType.emailAddress,
              controller: _emailCtrl,
            ),
            const SizedBox(height: 12),

            _buildPasswordField(context),
            const SizedBox(height: 12),

            _buildConfirmPasswordField(context),
            const SizedBox(height: 12),

            LabeledField(
              label: 'University',
              hint: 'Enter your university',
              controller: _universityCtrl,
            ),
            const SizedBox(height: 12),

            if (_isStudent) ...[
              LabeledField(
                label: 'Degree',
                hint: 'Enter your degree',
                controller: _degreeCtrl,
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Year of Study',
                hint: 'Enter your year of study',
                controller: _yearOfStudyCtrl,
              ),
              const SizedBox(height: 12),
            ],

            if (_isLecturer) ...[
              LabeledField(
                label: 'Department',
                hint: 'Enter your department',
                controller: _departmentCtrl,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 10),

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
                    Icons.mark_email_read_rounded,
                    color: colors.teal,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After creating your account, we will send a verification email. You must verify your email before logging in.',
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

            const SizedBox(height: 20),

            PrimaryButton(
              label: _isLoading ? 'Creating account...' : 'Create account',
              onTap: (_isLoading || !_canRegister) ? null : _doRegister,
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: _isLoading ? null : () => context.go('/Login'),
                child: Text(
                  'Already have an account? Log in',
                  style: TextStyle(
                    color: colors.teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}