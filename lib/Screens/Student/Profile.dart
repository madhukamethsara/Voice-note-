import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../Models/AppUser.dart';
import '../../Services/AuthService.dart';
import '../../Services/UserService.dart';

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
    _fullNameController.text = user.fullName;
    _universityController.text = user.university;
    _degreeController.text = user.degree ?? '';
    _yearController.text = user.yearOfStudy ?? '';
    _departmentController.text = user.department ?? '';

    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing(AppUser user) {
    _fullNameController.text = user.fullName;
    _universityController.text = user.university;
    _degreeController.text = user.degree ?? '';
    _yearController.text = user.yearOfStudy ?? '';
    _departmentController.text = user.department ?? '';

    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveChanges(AppUser user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

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

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8B92B8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF232840)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00E5B0)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildProfileRow(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8B92B8),
          fontSize: 13,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          color: Color(0xFFF0F2FF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentFirebaseUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('No logged-in user found'),
        ),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: _userService.streamUserByUid(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0F14),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0F14),
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
          return const Scaffold(
            backgroundColor: Color(0xFF0D0F14),
            body: Center(
              child: Text(
                'User data not found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        if (!_isEditing) {
          _fillControllers(user);
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0D0F14),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: Color(0xFF232840),
                    child: Icon(
                      Icons.person,
                      size: 42,
                      color: Color(0xFF00E5B0),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Color(0xFFF0F2FF),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Color(0xFF8B92B8),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (_isEditing) {
                          _cancelEditing(user);
                        } else {
                          _startEditing(user);
                        }
                      },
                      child: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141720),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF232840)),
                    ),
                    child: _isEditing
                        ? Column(
                            children: [
                              _buildEditField(
                                label: 'Full Name',
                                controller: _fullNameController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Full name is required';
                                  }
                                  return null;
                                },
                              ),
                              _buildEditField(
                                label: 'University',
                                controller: _universityController,
                              ),
                              _buildEditField(
                                label: 'Degree',
                                controller: _degreeController,
                              ),
                              _buildEditField(
                                label: 'Year of Study',
                                controller: _yearController,
                              ),
                              _buildEditField(
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
                                    backgroundColor: const Color(0xFF00E5B0),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildProfileRow("University", user.university),
                              const Divider(color: Color(0xFF232840)),
                              _buildProfileRow(
                                "Degree",
                                user.degree ?? 'Not set',
                              ),
                              const Divider(color: Color(0xFF232840)),
                              _buildProfileRow(
                                "Year",
                                user.yearOfStudy ?? 'Not set',
                              ),
                              const Divider(color: Color(0xFF232840)),
                              _buildProfileRow(
                                "Department",
                                user.department ?? 'Not set',
                              ),
                              const Divider(color: Color(0xFF232840)),
                              _buildProfileRow("Role", user.role),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _authService.signOut();
                        if (!context.mounted) return;
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                    ),
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