import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Theme/theme_helper.dart';
import '../widgets/commonwidget.dart';
import '../Services/auth/authservice.dart';


class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();

  final AuthService _authService = AuthService();

  String _selectedYear = 'Year 3';
  final List<String> _years = ['Year 1', 'Year 2', 'Year 3', 'Year 4'];

  bool _isLoading = false;

  bool get _isStudent => widget.role == 'student';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _uniCtrl.dispose();
    _deptCtrl.dispose();
    _degreeCtrl.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.trim().isEmpty ||
        _uniCtrl.text.trim().isEmpty) {
      _showSnack('Please fill all required fields');
      return;
    }

    if (_isStudent && _degreeCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your degree');
      return;
    }

    if (!_isStudent && _deptCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your department');
      return;
    }

    if (_passCtrl.text.trim().length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerUser(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        role: widget.role,
        university: _uniCtrl.text.trim(),
        degree: _isStudent ? _degreeCtrl.text.trim() : null,
        yearOfStudy: _isStudent ? _selectedYear : null,
        department: _isStudent ? null : _deptCtrl.text.trim(),
      );

      if (!mounted) return;

      _showSnack('Account created successfully');

     
      context.push('/onboarding');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    final colors = context.colors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.bg2,
        content: Text(msg, style: TextStyle(color: colors.text)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppTopBar(
        title: _isStudent ? 'Student Sign Up' : 'Lecturer Sign Up',
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Full name',
              hint: 'e.g. Ashan Perera',
              controller: _nameCtrl,
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Email',
              hint: 'you@university.edu',
              keyboardType: TextInputType.emailAddress,
              controller: _emailCtrl,
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Password',
              hint: 'Min. 6 characters',
              obscure: true,
              controller: _passCtrl,
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'University',
              hint: 'University of Colombo',
              controller: _uniCtrl,
            ),
            const SizedBox(height: 12),

            if (_isStudent) ...[
              LabeledField(
                label: 'Degree',
                hint: 'Software Engineering',
                controller: _degreeCtrl,
              ),
              const SizedBox(height: 12),
              Text(
                'Year of study',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.text2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _years
                    .map(
                      (y) => _YearPill(
                        label: y,
                        selected: _selectedYear == y,
                        onTap: () => setState(() => _selectedYear = y),
                      ),
                    )
                    .toList(),
              ),
            ],

            if (!_isStudent)
              LabeledField(
                label: 'Department',
                hint: 'e.g. Computer Science',
                controller: _deptCtrl,
              ),

            const SizedBox(height: 24),

            PrimaryButton(
              label: _isLoading ? 'Creating...' : 'Create Account',
              onTap: _isLoading ? () {} : _doRegister,
            ),
            const SizedBox(height: 8),
            OutlineButton2(
              label: 'Already have an account? Log in',
              onTap: () => context.push('/login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YearPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.teal.withOpacity(0.12) : colors.bg2,
          border: Border.all(
            color: selected ? colors.teal : colors.bg3,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? colors.teal : colors.text2,
          ),
        ),
      ),
    );
  }
}
