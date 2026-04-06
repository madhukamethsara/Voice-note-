import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../Models/Recording.dart';
import '../../Models/NoteFileItem.dart';
import '../../Services/Recording/RecordingStorage.dart';
import '../../Services/Recording/RecordingFirestore.dart';
import '../../Services/Ai/Transcription.dart';
import '../../Services/Ai/Summary.dart';
import '../../Services/File/NoteFileStorage.dart';
import '../../Theme/theme_helper.dart';
import 'LecturerRecordingDetailScreen.dart';
import 'LecturerModulesScreen.dart';

class LecturerRecordScreen extends StatefulWidget {
  const LecturerRecordScreen({super.key});

  @override
  State<LecturerRecordScreen> createState() => _LecturerRecordScreenState();
}

class _LecturerRecordScreenState extends State<LecturerRecordScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final RecordingStorageService _storageService = RecordingStorageService();
  final RecordingFirestoreService _firestoreService =
      RecordingFirestoreService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final SummaryService _summaryService = SummaryService();
  final NoteFileStorageService _noteFileStorageService =
      NoteFileStorageService();

  late final AnimationController _pulseController;

  Timer? _recordTimer;
  Timer? _waveTimer;

  bool isRecording = false;
  bool showAiSection = false;
  bool _isSendingSummary = false;

  int seconds = 0;
  String? recordedFilePath;
  String? _latestRecordingId;
  String? _playingPath;

  String _latestTranscript = 'Transcript will come in the next step.';
  String _summaryText = 'Summary will come after transcription.';

  List<RecordingItem> _recentRecordings = [];

  final Random _random = Random();
  List<double> _waveHeights = [8, 16, 24, 12, 30, 18, 22, 10, 28, 14, 20, 8];

  static const String _defaultModuleName = 'Lecture Recordings';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (!state.playing) {
        setState(() {
          _playingPath = null;
        });
      }
    });

    _loadRecordings();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final items = await _storageService.getRecordings();
    if (!mounted) return;

    setState(() {
      _recentRecordings = items;
    });
  }

  RecordingItem? _findRecordingById(String? id) {
    if (id == null) return null;
    try {
      return _recentRecordings.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> _createRecordingPath() async {
    final baseDir = await getApplicationDocumentsDirectory();

    final moduleDir = Directory('${baseDir.path}/voice_notes/lecturer');

    if (!await moduleDir.exists()) {
      await moduleDir.create(recursive: true);
    }

    final now = DateTime.now();
    final fileName =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}.m4a';

    return '${moduleDir.path}/$fileName';
  }

  void _startTimer() {
    _recordTimer?.cancel();
    seconds = 0;

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        seconds++;
      });
    });
  }

  void _stopTimer() {
    _recordTimer?.cancel();
  }

  void _startWaveAnimation() {
    _waveTimer?.cancel();

    _waveTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted || !isRecording) return;
      setState(() {
        _waveHeights = List.generate(
          12,
          (_) => 6 + _random.nextInt(28).toDouble(),
        );
      });
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _waveHeights = List.generate(12, (_) => 8);
    });
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();

      if (!hasPermission) {
        _showSnack('Microphone permission not granted');
        return;
      }

      final path = await _createRecordingPath();

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      if (!mounted) return;

      setState(() {
        isRecording = true;
        showAiSection = false;
        recordedFilePath = null;
        _latestRecordingId = null;
        _latestTranscript = 'Transcript will come in the next step.';
        _summaryText = 'Summary will come after transcription.';
      });

      _startTimer();
      _startWaveAnimation();
      _pulseController.repeat();
    } catch (e) {
      _showSnack('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      _stopTimer();
      _stopWaveAnimation();
      _pulseController.stop();

      RecordingItem? savedItem;

      if (path != null) {
        final file = File(path);

        if (await file.exists()) {
          savedItem = RecordingItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            module: _defaultModuleName,
            path: path,
            durationSeconds: seconds,
            createdAt: DateTime.now(),
            transcript: null,
            summary: null,
            isTranscribing: false,
            isSummarizing: false,
          );

          await _storageService.saveRecording(savedItem);
          await _firestoreService.saveRecording(savedItem);
        }
      }

      if (!mounted) return;

      setState(() {
        isRecording = false;
        showAiSection = true;
        recordedFilePath = path;
        _latestRecordingId = savedItem?.id;
      });

      await _loadRecordings();

      _showSnack(path == null ? 'Recording stopped' : 'Recording saved');

      if (savedItem != null) {
        await _transcribeRecording(savedItem);
      }
    } catch (e) {
      _showSnack('Failed to stop recording: $e');
    }
  }

  Future<void> _transcribeRecording(RecordingItem item) async {
    try {
      final loadingItem = item.copyWith(isTranscribing: true);
      await _storageService.updateRecording(loadingItem);
      await _firestoreService.updateRecording(loadingItem);
      await _loadRecordings();

      if (mounted) {
        setState(() {
          _latestTranscript = 'Transcribing...';
          _summaryText = 'Summary will come after transcription.';
        });
      }

      final transcript = await _transcriptionService.transcribeAudio(item.path);

      final updatedItem = item.copyWith(
        transcript: transcript,
        isTranscribing: false,
      );

      await _storageService.updateRecording(updatedItem);
      await _firestoreService.updateRecording(updatedItem);
      await _loadRecordings();

      if (!mounted) return;

      setState(() {
        _latestTranscript = transcript.trim().isEmpty
            ? 'No transcript returned.'
            : transcript;
      });

      _showSnack('Transcript ready');
    } catch (e) {
      final failedItem = item.copyWith(isTranscribing: false);
      await _storageService.updateRecording(failedItem);
      await _loadRecordings();

      if (!mounted) return;

      setState(() {
        _latestTranscript = 'Transcription failed: $e';
      });

      _showSnack('Transcription failed');
    }
  }

  Future<void> _generateSummary() async {
    if (_isSendingSummary) return;

    try {
      final currentItem = _findRecordingById(_latestRecordingId);

      if (currentItem == null) {
        _showSnack('No recording selected for summary');
        return;
      }

      final transcript = currentItem.transcript?.trim() ?? '';

      if (transcript.isEmpty ||
          transcript == 'Transcribing...' ||
          transcript.contains('failed')) {
        _showSnack('No valid transcript available');
        return;
      }

      setState(() {
        _isSendingSummary = true;
        _summaryText = 'Generating summary...';
      });

      final loadingItem = currentItem.copyWith(isSummarizing: true);
      await _storageService.updateRecording(loadingItem);
      await _firestoreService.updateRecording(loadingItem);
      await _loadRecordings();

      final summary = await _summaryService.summarizeText(transcript);

      final updatedItem = loadingItem.copyWith(
        summary: summary.trim().isEmpty ? 'No summary generated.' : summary,
        isSummarizing: false,
      );

      await _storageService.updateRecording(updatedItem);
      await _firestoreService.updateRecording(updatedItem);
      await _loadRecordings();

      if (!mounted) return;

      setState(() {
        _summaryText = updatedItem.summary ?? 'No summary generated.';
      });

      _showSnack('Summary ready');
    } catch (e) {
      final currentItem = _findRecordingById(_latestRecordingId);
      if (currentItem != null) {
        final failedItem = currentItem.copyWith(isSummarizing: false);
        await _storageService.updateRecording(failedItem);
        await _loadRecordings();
      }

      if (!mounted) return;

      setState(() {
        _summaryText = 'Summary failed: $e';
      });

      _showSnack('Summary failed');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingSummary = false;
        });
      }
    }
  }

  Future<void> _saveToNotes() async {
    try {
      final currentItem = _findRecordingById(_latestRecordingId);

      if (currentItem == null) {
        _showSnack('No recording available to save');
        return;
      }

      final noteFile = NoteFileItem(
        id: currentItem.id,
        title: 'Lecture Recording',
        moduleName: currentItem.module,
        moduleCode: '',
        type: 'recording',
        audioPath: currentItem.path,
        transcript: currentItem.transcript,
        summary: currentItem.summary,
        createdAt: currentItem.createdAt,
        updatedAt: DateTime.now(),
      );

      await _noteFileStorageService.saveFile(noteFile);

      _showSnack('Saved to Notes');
    } catch (e) {
      _showSnack('Save failed: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _togglePlayback(RecordingItem item) async {
    try {
      if (_playingPath == item.path) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _playingPath = null;
        });
        return;
      }

      final file = File(item.path);
      if (!await file.exists()) {
        _showSnack('Audio file not found');
        return;
      }

      await _audioPlayer.setFilePath(item.path);
      await _audioPlayer.play();

      if (!mounted) return;
      setState(() {
        _playingPath = item.path;
      });
    } catch (e) {
      _showSnack('Playback failed: $e');
    }
  }

  Future<void> _deleteRecording(RecordingItem item) async {
    try {
      if (_playingPath == item.path) {
        await _audioPlayer.stop();
      }

      final file = File(item.path);
      if (await file.exists()) {
        await file.delete();
      }

      await _storageService.deleteRecording(item.id);
      await _firestoreService.deleteRecording(item.id);

      await _loadRecordings();

      if (!mounted) return;

      if (_latestRecordingId == item.id) {
        setState(() {
          _latestRecordingId = null;
          recordedFilePath = null;
          _latestTranscript = 'Transcript will come in the next step.';
          _summaryText = 'Summary will come after transcription.';
        });
      }

      _showSnack('Recording deleted');
    } catch (e) {
      _showSnack('Delete failed: $e');
    }
  }

  Future<void> _openRecordingDetails(RecordingItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerRecordingDetailScreen(recording: item),
      ),
    );

    await _loadRecordings();

    if (!mounted) return;

    final refreshedItem = _findRecordingById(item.id);
    if (refreshedItem != null && _latestRecordingId == refreshedItem.id) {
      setState(() {
        _latestTranscript = refreshedItem.transcript?.trim().isNotEmpty == true
            ? refreshedItem.transcript!
            : 'Transcript will come in the next step.';
        _summaryText = refreshedItem.summary?.trim().isNotEmpty == true
            ? refreshedItem.summary!
            : 'Summary will come after transcription.';
      });
    }
  }

  void _showSnack(String message) {
    final colors = context.colors;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.bg2,
        content: Text(
          message,
          style: GoogleFonts.dmSans(color: colors.text, fontSize: 13),
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDurationLabel(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '$minutes min';
    }
    return '$secs sec';
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);

    if (itemDay == today) return 'Today';

    final yesterday = today.subtract(const Duration(days: 1));
    if (itemDay == yesterday) return 'Yesterday';

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildWaveform(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _waveHeights.map((height) {
          return Container(
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: colors.teal.withOpacity(isRecording ? 1 : 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final spread = isRecording ? 16 * _pulseController.value : 0.0;
        final opacity = isRecording
            ? (0.4 * (1 - _pulseController.value))
            : 0.0;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isRecording
                ? [
                    BoxShadow(
                      color: colors.coral.withOpacity(opacity),
                      spreadRadius: spread,
                      blurRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? colors.coral.withOpacity(0.20)
                    : colors.teal.withOpacity(0.12),
                border: Border.all(
                  color: isRecording ? colors.coral : colors.teal,
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('🎙️', style: TextStyle(fontSize: 32)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecorderSection(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.bg4),
      ),
      child: Column(
        children: [
          _buildWaveform(context),
          const SizedBox(height: 14),
          if (isRecording || showAiSection)
            Text(
              _formatTime(seconds),
              style: GoogleFonts.syne(
                color: colors.coral,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (isRecording || showAiSection) const SizedBox(height: 14),
          _buildRecordButton(context),
          const SizedBox(height: 14),
          Text(
            isRecording ? 'Recording lecture...' : 'Tap to start recording',
            style: GoogleFonts.dmSans(
              color: isRecording ? colors.coral : colors.text2,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: colors.text3,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTranscriptBox(
    BuildContext context, {
    required String value,
    Color? textColor,
  }) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.bg4),
      ),
      child: Text(
        value,
        style: GoogleFonts.dmSans(
          color: textColor ?? colors.text2,
          fontSize: 12,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSmallButton(
    BuildContext context, {
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: primary ? 16 : 18,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: primary ? colors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: primary ? null : Border.all(color: colors.bg4, width: 1.4),
        ),
        child: Text(
          label,
          style: GoogleFonts.syne(
            color: primary ? colors.black : colors.text2,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAiSection(BuildContext context) {
    final colors = context.colors;

    if (!showAiSection) return const SizedBox.shrink();

    final currentItem = _findRecordingById(_latestRecordingId);
    final isSummarizing = currentItem?.isSummarizing ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'AI Transcript'),
        _buildTranscriptBox(context, value: _latestTranscript),
        _buildSectionTitle(context, 'AI Summary'),
        _buildTranscriptBox(
          context,
          value: _summaryText,
          textColor: colors.text,
        ),
        if (recordedFilePath != null) ...[
          const SizedBox(height: 8),
          Text(
            recordedFilePath!,
            style: GoogleFonts.dmSans(color: colors.text3, fontSize: 10),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            _buildSmallButton(
              context,
              label: isSummarizing || _isSendingSummary
                  ? 'Generating...'
                  : '✨ Summarise',
              primary: true,
              onTap: isSummarizing || _isSendingSummary
                  ? () {}
                  : _generateSummary,
            ),
            const SizedBox(width: 8),
            _buildSmallButton(
              context,
              label: 'Save to Notes',
              primary: false,
              onTap: _saveToNotes,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordingTile(BuildContext context, RecordingItem item) {
    final colors = context.colors;
    final isPlaying = _playingPath == item.path;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openRecordingDetails(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg4),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _togglePlayback(item),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isPlaying ? '⏸' : '▶',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.module,
                    style: GoogleFonts.syne(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDurationLabel(item.durationSeconds)} · ${_formatDayLabel(item.createdAt)}',
                    style: GoogleFonts.dmSans(
                      color: colors.text2,
                      fontSize: 12,
                    ),
                  ),
                  if (item.isTranscribing) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Transcribing...',
                      style: GoogleFonts.dmSans(
                        color: colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (item.isSummarizing) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Generating summary...',
                      style: GoogleFonts.dmSans(
                        color: colors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (item.summary != null &&
                      item.summary!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: colors.text2,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _deleteRecording(item),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.text2,
                size: 20,
              ),
            ),
          ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lecture Recording',
                      style: GoogleFonts.syne(
                        color: colors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LecturerModulesScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.menu_book_rounded, color: colors.text2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Record lectures, generate transcript, and create summary.',
                style: GoogleFonts.dmSans(
                  color: colors.text2,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _buildRecorderSection(context),
              _buildAiSection(context),
              _buildSectionTitle(context, 'Recent Recordings'),
              if (_recentRecordings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bg2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.bg4),
                  ),
                  child: Text(
                    'No recordings yet.',
                    style: GoogleFonts.dmSans(
                      color: colors.text2,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ..._recentRecordings.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildRecordingTile(context, item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
