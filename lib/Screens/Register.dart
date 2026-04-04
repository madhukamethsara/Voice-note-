import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Theme/theme.dart';
import '../widgets/commonwidget.dart';
import '../Services/AuthService.dart';

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
  
  final Map<String, String?> _errors = {};

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

  Future<void> _doRegister() async {
    _clearErrors();

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final uni = _uniCtrl.text.trim();
    final degree = _degreeCtrl.text.trim();
    final dept = _deptCtrl.text.trim();

    if (name.isEmpty) return _setFieldError('name', 'Name is required');
    if (email.isEmpty) return _setFieldError('email', 'Email is required');
    if (pass.isEmpty) return _setFieldError('pass', 'Password is required');
    if (uni.isEmpty) return _setFieldError('uni', 'University is required');

    if (_isStudent && degree.isEmpty) {
      return _setFieldError('degree', 'Degree is required');
    }
    if (!_isStudent && dept.isEmpty) {
      return _setFieldError('dept', 'Department is required');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return _setFieldError('email', 'Invalid email format');
    }

    if (pass.length < 6) {
      return _setFieldError('pass', 'Min. 6 characters');
    }
    if (!pass.contains(RegExp(r'[A-Z]'))) {
      return _setFieldError('pass', 'Needs an uppercase letter');
    }
    if (!pass.contains(RegExp(r'[a-z]'))) {
      return _setFieldError('pass', 'Needs a lowercase letter');
    }
    if (!pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_]'))) {
      return _setFieldError('pass', 'Needs a special character');
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerUser(
        fullName: name,
        email: email,
        password: pass,
        role: widget.role,
        university: uni,
        degree: _isStudent ? degree : null,
        yearOfStudy: _isStudent ? _selectedYear : null,
        department: _isStudent ? null : dept,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );

      if (_isStudent) {
        context.go('/Student/Dasboard');
      } else {
        // Updated to match your old file's correct path
        context.go('/Lecturer/Dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFieldLabel(String label, String? error) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: dmStyle(
            size: 11,
            weight: FontWeight.w500,
            color: AppColors.text2,
          ),
        ),
        if (error != null)
          Text(
            error,
            style: dmStyle(
              size: 10,
              weight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: _isStudent ? 'Student Sign Up' : 'Lecturer Sign Up',
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Full name', _errors['name']),
            const SizedBox(height: 4),
            LabeledField(
              label: '', 
              hint: 'e.g. Ashan Perera',
              controller: _nameCtrl,
              onChanged: (_) => setState(() => _errors['name'] = null),
            ),
            const SizedBox(height: 12),

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
              hint: 'Min. 6 chars, A-z, @',
              obscure: true,
              controller: _passCtrl,
              onChanged: (_) => setState(() => _errors['pass'] = null),
            ),
            const SizedBox(height: 12),

            _buildFieldLabel('University', _errors['uni']),
            const SizedBox(height: 4),
            LabeledField(
              label: '',
              hint: 'University of Colombo',
              controller: _uniCtrl,
              onChanged: (_) => setState(() => _errors['uni'] = null),
            ),
            const SizedBox(height: 12),

            if (_isStudent) ...[
              _buildFieldLabel('Degree', _errors['degree']),
              const SizedBox(height: 4),
              LabeledField(
                label: '',
                hint: 'Software Engineering',
                controller: _degreeCtrl,
                onChanged: (_) => setState(() => _errors['degree'] = null),
              ),
              const SizedBox(height: 12),
              Text(
                'Year of study',
                style: dmStyle(size: 11, weight: FontWeight.w500, color: AppColors.text2),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _years.map((y) => _YearPill(
                  label: y,
                  selected: _selectedYear == y,
                  onTap: () => setState(() => _selectedYear = y),
                )).toList(),
              ),
            ],

            if (!_isStudent) ...[
              _buildFieldLabel('Department', _errors['dept']),
              const SizedBox(height: 4),
              LabeledField(
                label: '',
                hint: 'e.g. Computer Science',
                controller: _deptCtrl,
                onChanged: (_) => setState(() => _errors['dept'] = null),
              ),
            ],

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

  const _YearPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal.withOpacity(0.12) : AppColors.bg2,
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.bg3,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: dmStyle(
            size: 12,
            weight: FontWeight.w500,
            color: selected ? AppColors.teal : AppColors.text2,
          ),
        ),
      ),
    );
  }
}