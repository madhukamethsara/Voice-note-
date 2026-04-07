import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../Theme/theme_helper.dart';
import '../../Theme/theme_notifier.dart';

class LecturerProfileScreen extends StatefulWidget {
  const LecturerProfileScreen({super.key});

  @override
  State<LecturerProfileScreen> createState() => _LecturerProfileScreenState();
}

class _LecturerProfileScreenState extends State<LecturerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _isSaving = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();

  User? get _currentUser => _auth.currentUser;

  String get _uid => _currentUser?.uid ?? '';

  @override
  void dispose() {
    _fullNameController.dispose();
    _departmentController.dispose();
    _universityController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getUserData() async {
    try {
      final doc =
          await _firestore.collection('users').doc(_uid).get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  void _fillControllers(Map<String, dynamic> data) {
    _fullNameController.text = data['displayName'] ?? _currentUser?.displayName ?? '';
    _departmentController.text = data['department'] ?? '';
    _universityController.text = data['university'] ?? '';
    _specializationController.text = data['specialization'] ?? '';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('users').doc(_uid).update({
        'displayName': _fullNameController.text.trim(),
        'department': _departmentController.text.trim(),
        'university': _universityController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.teal,
          content: Text(
            'Profile updated successfully',
            style: GoogleFonts.dmSans(color: context.colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.coral,
          content: Text(
            'Update failed: $e',
            style: GoogleFonts.dmSans(color: context.colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.colors;
        return AlertDialog(
          backgroundColor: colors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.syne(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.dmSans(
              color: colors.text2,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: colors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Logout',
                style: GoogleFonts.dmSans(
                  color: colors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    final colors = context.colors;

    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(color: colors.text2),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.dmSans(color: colors.text),
        decoration: _inputDecoration(label),
        validator: validator,
      ),
    );
  }

  Widget _buildProfileRow(
    BuildContext context,
    String title,
    String value,
  ) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: colors.text2,
              fontSize: 13,
            ),
          ),
          Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.dmSans(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeNotifier = context.watch<ThemeNotifier>();

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: Center(
          child: Text(
            'No logged-in user found',
            style: GoogleFonts.dmSans(color: colors.text),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Profile',
          style: GoogleFonts.syne(
            color: colors.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Theme Toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: colors.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.bg4),
              ),
              child: IconButton(
                onPressed: () {
                  themeNotifier.toggleTheme(!themeNotifier.isDarkMode);
                },
                icon: Icon(
                  themeNotifier.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: colors.amber,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          final colors = context.colors;
          final userData = snapshot.data ?? {};

          if (!_isEditing) {
            _fillControllers(userData);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.teal.withOpacity(0.2),
                          colors.blue.withOpacity(0.2),
                        ],
                      ),
                      border: Border.all(
                        color: colors.teal.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email (Non-editable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bg2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.bg4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Email',
                          style: GoogleFonts.dmSans(
                            color: colors.text2,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _currentUser?.email ?? '-',
                          style: GoogleFonts.dmSans(
                            color: colors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Type Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.teal.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 18,
                          color: colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lecturer Account',
                          style: GoogleFonts.dmSans(
                            color: colors.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Edit/Save Buttons
                  if (!_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: Icon(Icons.edit_rounded, color: colors.white),
                        label: Text(
                          'Edit Profile',
                          style: GoogleFonts.syne(
                            color: colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Profile Information Section
                  if (_isEditing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style: GoogleFonts.syne(
                            color: colors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEditField(
                          label: 'Full Name',
                          controller: _fullNameController,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        _buildEditField(
                          label: 'Department',
                          controller: _departmentController,
                        ),
                        _buildEditField(
                          label: 'University',
                          controller: _universityController,
                        ),
                        _buildEditField(
                          label: 'Specialization',
                          controller: _specializationController,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _isEditing = false);
                                  _fillControllers(userData);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.bg2,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: colors.bg4),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.dmSans(
                                    color: colors.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveChanges,
                                icon: _isSaving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                colors.white,
                                              ),
                                        ),
                                      )
                                    : Icon(Icons.save_rounded,
                                        color: colors.white),
                                label: Text(
                                  'Save',
                                  style: GoogleFonts.dmSans(
                                    color: colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.teal,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style: GoogleFonts.syne(
                            color: colors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildProfileRow(
                          context,
                          'Full Name',
                          _fullNameController.text,
                        ),
                        _buildProfileRow(
                          context,
                          'Department',
                          _departmentController.text,
                        ),
                        _buildProfileRow(
                          context,
                          'University',
                          _universityController.text,
                        ),
                        _buildProfileRow(
                          context,
                          'Specialization',
                          _specializationController.text,
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout_rounded, color: colors.white),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.syne(
                          color: colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.coral,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
