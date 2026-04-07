import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Theme/theme_helper.dart';
import '../common/ModuleChatScreen.dart';

class LecturerModulesScreen extends StatefulWidget {
  const LecturerModulesScreen({super.key});

  @override
  State<LecturerModulesScreen> createState() => _LecturerModulesScreenState();
}

class _LecturerModulesScreenState extends State<LecturerModulesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _lecturerName = 'Lecturer';

  @override
  void initState() {
    super.initState();
    _loadLecturerName();
  }

  Future<void> _loadLecturerName() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      _lecturerName = data['fullName'] ?? 'Lecturer';
    }
  }

  /// 🔥 MAIN STREAM: GET MODULES FROM CHAT DATABASE
  Stream<List<Map<String, String>>> _getModulesFromChat() {
    return _firestore.collection('module_chats').snapshots().map((snapshot) {
      final modules = <Map<String, String>>[];

      for (var doc in snapshot.docs) {
        final moduleCode = doc.id;

        modules.add({
          'code': moduleCode,
          'name': moduleCode, // you can improve later
        });
      }

      return modules;
    });
  }

  void _openChat(Map<String, String> module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleChatScreen(
          moduleCode: module['code']!,
          moduleName: module['name']!,
          senderName: _lecturerName,
          senderRole: 'lecturer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Module Chats',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<List<Map<String, String>>>(
                  stream: _getModulesFromChat(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colors.teal,
                        ),
                      );
                    }

                    final modules = snapshot.data!;

                    if (modules.isEmpty) {
                      return Center(
                        child: Text(
                          'No chats available',
                          style: TextStyle(color: colors.text2),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final module = modules[index];

                        return InkWell(
                          onTap: () => _openChat(module),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.bg2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.bg4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat,
                                  color: colors.teal,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    module['code']!,
                                    style: TextStyle(
                                      color: colors.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: colors.text3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}