import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Theme/theme.dart';
import '../widgets/commonwidget.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole; // 'student' | 'lecturer' | null
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
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
    return Scaffold(
      backgroundColor: AppColors.bg,
  appBar: AppBar(
    backgroundColor: AppColors.bg,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      color: AppColors.text, // match your theme
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

                // Title
                Text('Who are you?',
                    style: syneStyle(size: 24, weight: FontWeight.w700),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'Choose your role to get started',
                  style: dmStyle(size: 13, color: AppColors.text2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Role cards
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

// Cards
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withOpacity(0.06)
              : AppColors.bg2,
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.bg3,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(title,
                style: syneStyle(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: dmStyle(size: 12, color: AppColors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      
    );
  }  
}
