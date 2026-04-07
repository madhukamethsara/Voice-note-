import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Theme/theme_helper.dart';
import 'LecturerFolderItemsScreen.dart';

class LecturerFilesScreen extends StatefulWidget {
  const LecturerFilesScreen({super.key});

  @override
  State<LecturerFilesScreen> createState() => _LecturerFilesScreenState();
}

class _LecturerFilesScreenState extends State<LecturerFilesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _foldersRef {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('lecture_folders');
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _foldersStream() {
    return _foldersRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> _createFolder() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.colors;

        return AlertDialog(
          backgroundColor: colors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Create Folder',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                context,
                controller: nameCtrl,
                hint: 'Folder name',
              ),
              const SizedBox(height: 12),
              _dialogField(
                context,
                controller: descCtrl,
                hint: 'Description',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.text2),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final name = nameCtrl.text.trim();
    final description = descCtrl.text.trim();

    if (name.isEmpty) {
      _showSnack('Folder name is required');
      return;
    }

    final doc = _foldersRef.doc();

    await doc.set({
      'id': doc.id,
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _showSnack('Folder created');
  }

  Future<void> _editFolder(
    String folderId,
    Map<String, dynamic> data,
  ) async {
    final nameCtrl =
        TextEditingController(text: (data['name'] ?? '').toString());
    final descCtrl =
        TextEditingController(text: (data['description'] ?? '').toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.colors;

        return AlertDialog(
          backgroundColor: colors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Edit Folder',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                context,
                controller: nameCtrl,
                hint: 'Folder name',
              ),
              const SizedBox(height: 12),
              _dialogField(
                context,
                controller: descCtrl,
                hint: 'Description',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.text2),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final name = nameCtrl.text.trim();
    final description = descCtrl.text.trim();

    if (name.isEmpty) {
      _showSnack('Folder name is required');
      return;
    }

    await _foldersRef.doc(folderId).update({
      'name': name,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _showSnack('Folder updated');
  }

  Future<void> _deleteFolder(String folderId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.colors;

        return AlertDialog(
          backgroundColor: colors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Delete Folder',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Do you want to delete this folder? Delete items inside it first.',
            style: TextStyle(
              color: colors.text2,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.text2),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: colors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final items = await _foldersRef.doc(folderId).collection('items').get();
    if (items.docs.isNotEmpty) {
      _showSnack('This folder still has items inside it');
      return;
    }

    await _foldersRef.doc(folderId).delete();
    _showSnack('Folder deleted');
  }

  Widget _dialogField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    final colors = context.colors;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: colors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.text3),
        filled: true,
        fillColor: colors.bg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.bg4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.teal),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    final colors = context.colors;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.bg2,
        content: Text(
          message,
          style: TextStyle(
            color: colors.text,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _openFolder(String folderId, String folderName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerFolderItemsScreen(
          folderId: folderId,
          folderName: folderName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _createFolder,
        backgroundColor: colors.teal,
        foregroundColor: colors.black,
        child: const Icon(Icons.create_new_folder_rounded),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Folders',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create folders and keep recordings, transcripts, and summaries inside them.',
                style: TextStyle(
                  color: colors.text2,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  stream: _foldersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: colors.teal),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load folders',
                          style: TextStyle(
                            color: colors.coral,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data ?? [];

                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.bg2,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: colors.bg4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 46,
                              color: colors.text3,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No folders yet',
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create your first folder using the button below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.text2,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final folderName =
                            (data['name'] ?? 'Untitled Folder').toString();
                        final description =
                            (data['description'] ?? '').toString();

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openFolder(doc.id, folderName),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.bg2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.bg4),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colors.bg3,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.folder_rounded,
                                    color: colors.teal,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        folderName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.text,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        description.isNotEmpty
                                            ? description
                                            : 'No description',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.text2,
                                          fontSize: 12,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  color: colors.bg2,
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    color: colors.text3,
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _editFolder(doc.id, data);
                                    } else if (value == 'delete') {
                                      await _deleteFolder(doc.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
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