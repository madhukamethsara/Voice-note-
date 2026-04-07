import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voicenote/Models/Recording.dart';

import '../../Theme/theme.dart';
import '../../Theme/theme_helper.dart';

class LecturerRecordingDetailScreen extends StatefulWidget {
  final RecordingItem recording;

  const LecturerRecordingDetailScreen({
    super.key,
    required this.recording,
  });

  @override
  State<LecturerRecordingDetailScreen> createState() =>
      _LecturerRecordingDetailScreenState();
}

class _LecturerRecordingDetailScreenState
    extends State<LecturerRecordingDetailScreen> {
  late final AudioPlayer _audioPlayer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedTab = 0;
  bool _isPlaying = false;

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

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _summaryText {
    final summary = widget.recording.summary?.trim() ?? '';
    if (summary.isEmpty) {
      return 'No summary available yet.';
    }
    return summary;
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.toString().split('.').first;
  }

  Future<void> _playAudio() async {
    try {
      final file = File(widget.recording.path);

      if (!await file.exists()) {
        if (!mounted) return;

        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.bg3,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Audio file not found',
              style: GoogleFonts.dmSans(
                color: colors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        return;
      }

      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.setFilePath(widget.recording.path);
        await _audioPlayer.play();
      }
    } catch (e) {
      if (!mounted) return;

      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bg3,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Playback failed: $e',
            style: GoogleFonts.dmSans(
              color: colors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _saveToFiles() async {
    final colors = context.colors;

    try {
      // Fetch folders from Firestore
      final foldersSnapshot =
          await _foldersRef.orderBy('updatedAt', descending: true).get();

      if (!mounted) return;

      if (foldersSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.bg3,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No folders found. Create a folder first.',
              style: GoogleFonts.dmSans(color: colors.text),
            ),
          ),
        );
        return;
      }

      // Show folder selection bottom sheet
      final selectedFolder = await showModalBottomSheet<
          Map<String, dynamic>>(
        context: context,
        backgroundColor: colors.bg2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Folder',
                  style: GoogleFonts.syne(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose where to save this recording',
                  style: GoogleFonts.dmSans(
                    color: colors.text2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: foldersSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      final folderDoc = foldersSnapshot.docs[index];
                      final folderId = folderDoc.id;
                      final folderData = folderDoc.data();
                      final folderName =
                          folderData['name'] ?? 'Untitled Folder';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.folder_rounded,
                          color: colors.teal,
                        ),
                        title: Text(
                          folderName,
                          style: GoogleFonts.dmSans(
                            color: colors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: folderData['description'] != null
                            ? Text(
                                folderData['description'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  color: colors.text2,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        onTap: () => Navigator.pop(
                          context,
                          {
                            'id': folderId,
                            'name': folderName,
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (selectedFolder == null) return;

      // Show title dialog
      final titleCtrl = TextEditingController(
        text: 'Recording ${_formatDateTime(widget.recording.createdAt)}',
      );

      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: colors.bg2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Recording Title',
              style: GoogleFonts.syne(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: TextField(
              controller: titleCtrl,
              style: GoogleFonts.dmSans(
                color: colors.text,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter file title',
                hintStyle: GoogleFonts.dmSans(
                  color: colors.text2,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: colors.bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.bg4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.teal, width: 1.4),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.dmSans(
                    color: colors.text2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  'Save',
                  style: GoogleFonts.dmSans(
                    color: colors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (result != true) return;

      // Save to the selected folder
      final folderId = selectedFolder['id'];
      final title = titleCtrl.text.trim().isEmpty
          ? 'Recording ${_formatDateTime(widget.recording.createdAt)}'
          : titleCtrl.text.trim();

      final itemsRef =
          _foldersRef.doc(folderId).collection('items');

      await itemsRef.add({
        'id': widget.recording.id,
        'title': title,
        'type': 'recording',
        'audioPath': widget.recording.path,
        'transcript': widget.recording.transcript,
        'summary': widget.recording.summary,
        'createdAt': widget.recording.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update folder's updatedAt timestamp
      await _foldersRef.doc(folderId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bg3,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Saved to ${selectedFolder['name']} successfully',
            style: GoogleFonts.dmSans(
              color: colors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bg3,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to save: $e',
            style: GoogleFonts.dmSans(
              color: colors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTab(String title, int index) {
    final colors = context.colors;
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.bg3 : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.teal.withOpacity(0.45) : colors.bg4,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                color: isSelected ? colors.teal : colors.text2,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
  }) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.bg4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildContentText(String text) {
    final colors = context.colors;

    return Text(
      text,
      style: GoogleFonts.dmSans(
        color: colors.text2,
        fontSize: 13.5,
        height: 1.7,
      ),
    );
  }

  Widget _buildStatusChip(String text, {bool highlighted = false}) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? colors.teal.withOpacity(0.14) : colors.bg3,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? colors.teal.withOpacity(0.40) : colors.bg4,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: highlighted ? colors.teal : colors.text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fileExists = File(widget.recording.path).existsSync();

    return WillPopScope(
      onWillPop: () async {
        await _audioPlayer.stop();
        return true;
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.bg,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            onPressed: () async {
              await _audioPlayer.stop();
              if (!mounted) return;
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.chevron_left_rounded,
              color: colors.text,
              size: 28,
            ),
          ),
          title: Text(
            'Recording Details',
            style: GoogleFonts.syne(
              color: colors.text,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              color: colors.bg2,
              surfaceTintColor: colors.bg2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: Icon(Icons.more_vert_rounded, color: colors.text),
              onSelected: (value) {
                if (value == 'save') {
                  _saveToFiles();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save_rounded, color: colors.teal, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Save to Files',
                        style: GoogleFonts.dmSans(
                          color: colors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fileExists
                            ? colors.teal.withOpacity(0.14)
                            : colors.bg3,
                        border: Border.all(
                          color: fileExists
                              ? colors.teal.withOpacity(0.35)
                              : colors.bg4,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: fileExists ? _playAudio : null,
                          borderRadius: BorderRadius.circular(44),
                          child: Center(
                            child: Icon(
                              fileExists
                                  ? (_isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded)
                                  : Icons.error_outline_rounded,
                              color: fileExists ? colors.teal : colors.text2,
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatDuration(widget.recording.durationSeconds),
                      style: GoogleFonts.syne(
                        color: colors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(widget.recording.createdAt),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: colors.text2,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildStatusChip(
                      fileExists ? 'Audio available' : 'File not found',
                      highlighted: fileExists,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Row(
                children: [
                  _buildTab('Transcript', 0),
                  const SizedBox(width: 10),
                  _buildTab('Summary', 1),
                  const SizedBox(width: 10),
                  _buildTab('Details', 2),
                ],
              ),
              const SizedBox(height: 18),

              if (_selectedTab == 0)
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transcript',
                        style: GoogleFonts.syne(
                          color: colors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildContentText(
                        widget.recording.transcript?.trim().isNotEmpty == true
                            ? widget.recording.transcript!
                            : 'No transcript available yet.',
                      ),
                    ],
                  ),
                )
              else if (_selectedTab == 1)
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: GoogleFonts.syne(
                          color: colors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildContentText(_summaryText),
                    ],
                  ),
                )
              else
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: GoogleFonts.syne(
                          color: colors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _detailRow('Module', widget.recording.module, colors),
                      _detailRow(
                        'Duration',
                        _formatDuration(widget.recording.durationSeconds),
                        colors,
                      ),
                      _detailRow(
                        'Recording File',
                        fileExists ? 'Saved locally' : 'File not found',
                        colors,
                      ),
                      _detailRow(
                        'Transcription',
                        widget.recording.isTranscribing
                            ? 'In progress...'
                            : (widget.recording.transcript != null
                                ? 'Completed'
                                : 'Not started'),
                        colors,
                      ),
                      _detailRow(
                        'Summary',
                        widget.recording.isSummarizing
                            ? 'In progress...'
                            : (widget.recording.summary != null
                                ? 'Completed'
                                : 'Not started'),
                        colors,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bg3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: colors.text2,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                color: colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}