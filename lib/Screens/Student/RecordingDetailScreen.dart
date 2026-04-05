import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voicenote/Models/Recording.dart';

import '../../Models/Module.dart';
import '../../Models/NoteFileItem.dart';
import '../../Services/File/ModuleService.dart';
import '../../Services/File/NoteFile.dart';
import '../../Services/Recording/RecordingFirestore.dart';
import '../../Theme/theme_helper.dart';

class RecordingDetailScreen extends StatefulWidget {
  final RecordingItem recording;

  const RecordingDetailScreen({
    super.key,
    required this.recording,
  });

  @override
  State<RecordingDetailScreen> createState() => _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends State<RecordingDetailScreen> {
  late final AudioPlayer _audioPlayer;

  final ModuleService _moduleService = ModuleService();
  final NoteFileService _noteFileService = NoteFileService();
  final RecordingFirestoreService _recordingFirestoreService =
      RecordingFirestoreService();

  int _selectedTab = 0;
  bool _isPlaying = false;

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _togglePlayback() async {
    final colors = context.colors;

    try {
      final file = File(widget.recording.path);

      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.bg3,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Audio file not found',
              style: GoogleFonts.dmSans(color: colors.text),
            ),
          ),
        );
        return;
      }

      if (_isPlaying) {
        await _audioPlayer.stop();
        return;
      }

      await _audioPlayer.setFilePath(widget.recording.path);
      await _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bg3,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Playback failed: $e',
            style: GoogleFonts.dmSans(color: colors.text),
          ),
        ),
      );
    }
  }

  Future<void> _showMoveToModuleSheet() async {
    final colors = context.colors;

    try {
      final modules = await _moduleService.getUserModules();

      if (!mounted) return;

      if (modules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colors.bg3,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No modules found',
              style: GoogleFonts.dmSans(color: colors.text),
            ),
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: colors.bg2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          final sheetColors = sheetContext.colors;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move to Module',
                  style: GoogleFonts.syne(
                    color: sheetColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a module for this recording',
                  style: GoogleFonts.dmSans(
                    color: sheetColors.text2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ...modules.map(
                  (module) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.folder_rounded,
                      color: sheetColors.teal,
                    ),
                    title: Text(
                      module.moduleName.isNotEmpty
                          ? module.moduleName
                          : module.moduleCode,
                      style: GoogleFonts.dmSans(
                        color: sheetColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      module.moduleCode,
                      style: GoogleFonts.dmSans(
                        color: sheetColors.text2,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _moveRecordingToModule(module);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bg3,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to load modules: $e',
            style: GoogleFonts.dmSans(color: colors.text),
          ),
        ),
      );
    }
  }

  Future<void> _moveRecordingToModule(Module module) async {
    final colors = context.colors;
    final recording = widget.recording;

    final noteFile = NoteFileItem(
      id: recording.id,
      title: "Recording ${recording.createdAt}",
      moduleName: module.moduleName,
      moduleCode: module.moduleCode,
      type: "recording",
      audioPath: recording.path,
      transcript: recording.transcript,
      summary: recording.summary,
      createdAt: recording.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _noteFileService.addFile(noteFile);

      await _recordingFirestoreService.updateRecording(
        recording.copyWith(module: module.moduleCode),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bg3,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Moved to ${module.moduleCode}',
            style: GoogleFonts.dmSans(color: colors.text),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bg3,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed: $e',
            style: GoogleFonts.dmSans(color: colors.text),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colors.teal : colors.bg4,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: isSelected ? colors.text : colors.text2,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBox() {
    final colors = context.colors;

    final content = _selectedTab == 0
        ? ((widget.recording.transcript?.trim().isNotEmpty ?? false)
              ? widget.recording.transcript!
              : 'No transcript available yet.')
        : _summaryText;

    final title = _selectedTab == 0 ? 'Transcript' : 'Summary';
    final icon = _selectedTab == 0
        ? Icons.description_rounded
        : Icons.auto_awesome_rounded;
    final iconColor = _selectedTab == 0 ? colors.purple : colors.amber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.bg4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.syne(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: GoogleFonts.dmSans(
              color: colors.text2,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fileExists = File(widget.recording.path).existsSync();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.chevron_left_rounded, color: colors.text),
        ),
        title: Text(
          widget.recording.module,
          style: GoogleFonts.syne(
            color: colors.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showMoveToModuleSheet,
            icon: Icon(Icons.more_horiz_rounded, color: colors.teal),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bg2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.bg4),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.bg3,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: colors.teal,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recording File',
                          style: GoogleFonts.syne(
                            color: colors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDuration(widget.recording.durationSeconds)} • ${_formatDate(widget.recording.createdAt)}',
                          style: GoogleFonts.dmSans(
                            color: colors.text2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fileExists ? 'Saved locally' : 'File not found',
                          style: GoogleFonts.dmSans(
                            color: fileExists ? colors.teal : colors.coral,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildTab('Transcription', 0),
                _buildTab('Summary', 1),
              ],
            ),
            const SizedBox(height: 18),
            _buildContentBox(),
          ],
        ),
      ),
    );
  }
}