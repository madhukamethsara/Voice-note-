import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Theme/theme_helper.dart';

class LecturerFolderItemsScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const LecturerFolderItemsScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<LecturerFolderItemsScreen> createState() =>
      _LecturerFolderItemsScreenState();
}

class _LecturerFolderItemsScreenState extends State<LecturerFolderItemsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isMoving = false;

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

  CollectionReference<Map<String, dynamic>> get _itemsRef {
    return _foldersRef.doc(widget.folderId).collection('items');
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _itemsStream() {
    return _itemsRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> _createItem() async {
    final titleCtrl = TextEditingController();
    final transcriptCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();

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
            'Create Item',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(context, controller: titleCtrl, hint: 'Title'),
                const SizedBox(height: 12),
                _dialogField(
                  context,
                  controller: transcriptCtrl,
                  hint: 'Transcript',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  context,
                  controller: summaryCtrl,
                  hint: 'Summary',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: colors.text2)),
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

    final title = titleCtrl.text.trim();
    final transcript = transcriptCtrl.text.trim();
    final summary = summaryCtrl.text.trim();

    if (title.isEmpty) {
      _showSnack('Title is required');
      return;
    }

    final doc = _itemsRef.doc();

    await doc.set({
      'id': doc.id,
      'title': title,
      'type': 'recording',
      'audioPath': '',
      'transcript': transcript,
      'summary': summary,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _foldersRef.doc(widget.folderId).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _showSnack('Item created');
  }

  Future<void> _editItem(String itemId, Map<String, dynamic> data) async {
    final titleCtrl = TextEditingController(
      text: (data['title'] ?? '').toString(),
    );
    final transcriptCtrl = TextEditingController(
      text: (data['transcript'] ?? '').toString(),
    );
    final summaryCtrl = TextEditingController(
      text: (data['summary'] ?? '').toString(),
    );

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
            'Edit Item',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(context, controller: titleCtrl, hint: 'Title'),
                const SizedBox(height: 12),
                _dialogField(
                  context,
                  controller: transcriptCtrl,
                  hint: 'Transcript',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  context,
                  controller: summaryCtrl,
                  hint: 'Summary',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: colors.text2)),
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

    final title = titleCtrl.text.trim();
    final transcript = transcriptCtrl.text.trim();
    final summary = summaryCtrl.text.trim();

    if (title.isEmpty) {
      _showSnack('Title is required');
      return;
    }

    await _itemsRef.doc(itemId).update({
      'title': title,
      'transcript': transcript,
      'summary': summary,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _foldersRef.doc(widget.folderId).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _showSnack('Item updated');
  }

  Future<void> _deleteItem(String itemId) async {
    await _itemsRef.doc(itemId).delete();

    await _foldersRef.doc(widget.folderId).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _showSnack('Item deleted');
  }

  Future<void> _showMoveToFolderDialog(
    String itemId,
    Map<String, dynamic> itemData,
  ) async {
    if (_isMoving) return;

    try {
      final snapshot = await _foldersRef
          .orderBy('updatedAt', descending: true)
          .get();

      final folderDocs = snapshot.docs
          .where((doc) => doc.id != widget.folderId)
          .toList();

      if (folderDocs.isEmpty) {
        _showSnack('No other folders available');
        return;
      }

      if (!mounted) return;

      final selectedFolder =
          await showModalBottomSheet<
            QueryDocumentSnapshot<Map<String, dynamic>>
          >(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) {
              final colors = context.colors;

              return Container(
                decoration: BoxDecoration(
                  color: colors.bg2,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.bg4,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Move to Folder',
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose a folder to move this item into',
                        style: TextStyle(color: colors.text2, fontSize: 12),
                      ),
                      const SizedBox(height: 18),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: folderDocs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final folderDoc = folderDocs[index];
                            final data = folderDoc.data();
                            final folderName =
                                (data['name'] ?? 'Untitled Folder').toString();
                            final description = (data['description'] ?? '')
                                .toString();

                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => Navigator.pop(context, folderDoc),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors.bg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: colors.bg4),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: colors.bg3,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.folder_rounded,
                                        color: colors.teal,
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
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            description.isNotEmpty
                                                ? description
                                                : 'No description',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colors.text2,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colors.text3,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

      if (selectedFolder == null) return;

      await _moveItemToFolder(
        itemId: itemId,
        itemData: itemData,
        targetFolderId: selectedFolder.id,
        targetFolderName: (selectedFolder.data()['name'] ?? 'Selected Folder')
            .toString(),
      );
    } catch (e) {
      _showSnack('Failed to load folders');
    }
  }

  Future<void> _moveItemToFolder({
    required String itemId,
    required Map<String, dynamic> itemData,
    required String targetFolderId,
    required String targetFolderName,
  }) async {
    if (_isMoving) return;

    setState(() => _isMoving = true);

    try {
      final sourceItemRef = _foldersRef
          .doc(widget.folderId)
          .collection('items')
          .doc(itemId);

      final targetItemRef = _foldersRef
          .doc(targetFolderId)
          .collection('items')
          .doc(itemId);

      final movedData = Map<String, dynamic>.from(itemData);
      movedData['id'] = itemId;
      movedData['updatedAt'] = FieldValue.serverTimestamp();

      if (!movedData.containsKey('createdAt') ||
          movedData['createdAt'] == null) {
        movedData['createdAt'] = FieldValue.serverTimestamp();
      }

      final batch = _firestore.batch();

      batch.set(targetItemRef, movedData, SetOptions(merge: true));
      batch.delete(sourceItemRef);

      batch.set(_foldersRef.doc(widget.folderId), {
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(_foldersRef.doc(targetFolderId), {
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      _showSnack('Item moved to $targetFolderName');
    } catch (e) {
      _showSnack('Failed to move item');
    } finally {
      if (mounted) {
        setState(() => _isMoving = false);
      }
    }
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
        content: Text(message, style: TextStyle(color: colors.text)),
      ),
    );
  }

  String _preview(Map<String, dynamic> data) {
    final summary = (data['summary'] ?? '').toString().trim();
    final transcript = (data['transcript'] ?? '').toString().trim();

    if (summary.isNotEmpty) return summary;
    if (transcript.isNotEmpty) return transcript;
    return 'No preview available';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _createItem,
        backgroundColor: colors.teal,
        foregroundColor: colors.black,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.chevron_left_rounded, color: colors.text),
        ),
        title: Text(
          widget.folderName,
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _itemsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: colors.teal),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load items',
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
                return Center(
                  child: Text(
                    'No items in this folder yet',
                    style: TextStyle(color: colors.text2, fontSize: 13),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bg2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.bg4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.bg3,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.mic_rounded,
                            color: colors.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['title'] ?? 'Untitled Item').toString(),
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
                                _preview(data),
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
                              await _editItem(doc.id, data);
                            } else if (value == 'move') {
                              await _showMoveToFolderDialog(doc.id, data);
                            } else if (value == 'delete') {
                              await _deleteItem(doc.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'move',
                              child: Text('Move to folder'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (_isMoving)
            Container(
              color: Colors.black.withOpacity(0.18),
              child: Center(
                child: CircularProgressIndicator(color: colors.teal),
              ),
            ),
        ],
      ),
    );
  }
}
