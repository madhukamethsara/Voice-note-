import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../Models/AppUser.dart';
import 'package:voicenote/Services/authservices.dart';
import '../../Services/UserService.dart';
import '../../Theme/theme_helper.dart';
import '../../Theme/theme_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _isSaving = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  String? _loadedUserId;

  @override
  void dispose() {
    _fullNameController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _yearController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _fillControllers(AppUser user) {
    if (_loadedUserId == user.uid) return;

    _fullNameController.text = user.fullName;
    _universityController.text = user.university;
    _degreeController.text = user.degree ?? '';
    _yearController.text = user.yearOfStudy ?? '';
    _departmentController.text = user.department ?? '';
    _loadedUserId = user.uid;
  }

  void _startEditing(AppUser user) {
    _fillControllers(user);
    setState(() => _isEditing = true);
  }

  void _cancelEditing(AppUser user) {
    _fillControllers(user);
    setState(() => _isEditing = false);
  }

  Future<void> _saveChanges(AppUser user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _userService.updateUserProfile(
        uid: user.uid,
        fullName: _fullNameController.text.trim(),
        university: _universityController.text.trim(),
        degree: _degreeController.text.trim(),
        yearOfStudy: _yearController.text.trim(),
        department: _departmentController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, BuildContext context) {
    final colors = context.colors;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.text2),
      filled: true,
      fillColor: colors.bg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.bg4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.teal),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildProfileRow(BuildContext context, String title, String value) {
    final colors = context.colors;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: colors.text2, fontSize: 13)),
      trailing: Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: colors.text),
        decoration: _inputDecoration(label, context),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    //final themeNotifier = context.watch<ThemeNotifier>();
    final currentUser = _authService.currentFirebaseUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: Center(
          child: Text(
            'No logged-in user found',
            style: TextStyle(color: colors.text),
          ),
        ),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: _userService.streamUserByUid(currentUser.uid),
      builder: (context, snapshot) {
        final colors = context.colors;
        final themeNotifier = context.watch<ThemeNotifier>();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: colors.bg,
            body: Center(child: CircularProgressIndicator(color: colors.teal)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: colors.bg,
            body: Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return Scaffold(
            backgroundColor: colors.bg,
            body: Center(
              child: Text(
                'User data not found',
                style: TextStyle(color: colors.text),
              ),
            ),
          );
        }

        if (!_isEditing) {
          _fillControllers(user);
        }

        return Scaffold(
          backgroundColor: colors.bg,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  CircleAvatar(
                    radius: 42,
                    backgroundColor: colors.bg4,
                    child: Icon(Icons.person, size: 42, color: colors.teal),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    user.fullName,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    user.email,
                    style: TextStyle(color: colors.text2, fontSize: 13),
                  ),

                  const SizedBox(height: 18),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _isEditing ? _cancelEditing(user) : _startEditing(user);
                      },
                      child: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.bg2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.bg4),
                    ),
                    child: _isEditing
                        ? Column(
                            children: [
                              _buildEditField(
                                context: context,
                                label: 'Full Name',
                                controller: _fullNameController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                              _buildEditField(
                                context: context,
                                label: 'University',
                                controller: _universityController,
                              ),
                              _buildEditField(
                                context: context,
                                label: 'Degree',
                                controller: _degreeController,
                              ),
                              _buildEditField(
                                context: context,
                                label: 'Year',
                                controller: _yearController,
                              ),
                              _buildEditField(
                                context: context,
                                label: 'Department',
                                controller: _departmentController,
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _saveChanges(user),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.teal,
                                    foregroundColor: colors.black,
                                  ),
                                  child: _isSaving
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: colors.black,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildProfileRow(
                                context,
                                "University",
                                user.university,
                              ),
                              Divider(color: colors.bg4),
                              _buildProfileRow(
                                context,
                                "Degree",
                                user.degree ?? 'Not set',
                              ),
                              Divider(color: colors.bg4),
                              _buildProfileRow(
                                context,
                                "Year",
                                user.yearOfStudy ?? 'Not set',
                              ),
                              Divider(color: colors.bg4),
                              _buildProfileRow(
                                context,
                                "Department",
                                user.department ?? 'Not set',
                              ),
                              Divider(color: colors.bg4),
                              _buildProfileRow(context, "Role", user.role),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.bg2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.bg4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: themeNotifier.isDarkMode,
                          onChanged: (value) {
                            themeNotifier.toggleTheme(value);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await _authService.signOut();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
