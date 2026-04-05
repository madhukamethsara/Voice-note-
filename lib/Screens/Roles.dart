import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Theme/theme_helper.dart';
import '../widgets/commonwidget.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _select(String role) {
    setState(() => _selectedRole = role);
  }

  void _continue() {
    if (_selectedRole == null) return;
    context.push('/register', extra: _selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () {
            context.go('/');
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Who are you?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose your role to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.text2, fontSize: 13),
                ),
                const SizedBox(height: 32),
                _RoleCard(
                  title: 'Student',
                  subtitle:
                      'Record lectures, get AI summaries, prepare for exams',
                  selected: _selectedRole == 'student',
                  onTap: () => _select('student'),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  title: 'Lecturer',
                  subtitle:
                      'Manage your lectures, notes, and student engagement',
                  selected: _selectedRole == 'lecturer',
                  onTap: () => _select('lecturer'),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Continue',
                  enabled: _selectedRole != null,
                  onTap: _continue,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? colors.teal.withOpacity(0.06) : colors.bg2,
          border: Border.all(
            color: selected ? colors.teal : colors.bg3,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: colors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text2, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
