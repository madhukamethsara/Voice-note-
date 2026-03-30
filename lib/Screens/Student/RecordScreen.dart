import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:voicenote/Models/Recording.dart';
import 'package:voicenote/Services/RecordingStorage.dart';
import 'package:voicenote/Services/Transcription.dart';
import 'package:voicenote/Services/Summary.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  static const Color bg = Color(0xFF0D0F14);
  static const Color bg2 = Color(0xFF141720);
  static const Color bg3 = Color(0xFF1C2030);
  static const Color bg4 = Color(0xFF232840);

  static const Color teal = Color(0xFF00E5B0);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color amber = Color(0xFFFFC145);

  static const Color text = Color(0xFFF0F2FF);
  static const Color text2 = Color(0xFF8B92B8);
  static const Color text3 = Color(0xFF555E7A);

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RecordingStorageService _storageService = RecordingStorageService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final SummaryService _summaryService = SummaryService();

  late final AnimationController _pulseController;

  Timer? _recordTimer;
  Timer? _waveTimer;

  String selectedModule = 'Data Structures';
  bool isRecording = false;
  bool showAiSection = false;
  int seconds = 0;
  String? recordedFilePath;
  String _latestTranscript = 'Transcript will come in the next step.';
  String _summaryText = 'Summary will come after transcription.';

  List<RecordingItem> _recentRecordings = [];
  String? _playingPath;

  final Random _random = Random();
  List<double> _waveHeights = [8, 16, 24, 12, 30, 18, 22, 10, 28, 14, 20, 8];

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

  Future<String> _createRecordingPath() async {
    final baseDir = await getApplicationDocumentsDirectory();

    final safeModule = selectedModule
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    final moduleDir = Directory('${baseDir.path}/voice_notes/$safeModule');

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
        _latestTranscript = 'Transcript will come in the next step.';
      });

      _startTimer();
      _startWaveAnimation();
      _pulseController.repeat();
      print('START RECORDING CALLED');
    } catch (e) {
      _showSnack('Failed to start recording: $e');
      print('START RECORDING ERROR: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      print('STOP RECORDING CALLED');

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
            module: selectedModule,
            path: path,
            durationSeconds: seconds,
            createdAt: DateTime.now(),
            transcript: null,
            isTranscribing: false,
          );

          await _storageService.saveRecording(savedItem);
        }
      }

      if (!mounted) return;

      setState(() {
        isRecording = false;
        showAiSection = true;
        recordedFilePath = path;
      });

      await _loadRecordings();

      _showSnack(path == null ? 'Recording stopped' : 'Recording saved');

      if (savedItem != null) {
        print('ABOUT TO START TRANSCRIPTION');
        _transcribeRecording(savedItem);
      }
    } catch (e, st) {
      _showSnack('Failed to stop recording: $e');
      print('STOP RECORDING ERROR: $e');
      print(st);
    }
  }

  Future<void> _transcribeRecording(RecordingItem item) async {
    try {
      print('TRANSCRIBE METHOD CALLED for: ${item.path}');

      final loadingItem = item.copyWith(isTranscribing: true);
      await _storageService.updateRecording(loadingItem);
      await _loadRecordings();

      if (mounted) {
        setState(() {
          _latestTranscript = 'Transcribing...';
        });
      }

      final transcript = await _transcriptionService.transcribeAudio(item.path);

      final updatedItem = item.copyWith(
        transcript: transcript,
        isTranscribing: false,
      );

      await _storageService.updateRecording(updatedItem);
      await _loadRecordings();

      if (!mounted) return;

      setState(() {
        _latestTranscript = transcript.trim().isEmpty
            ? 'No transcript returned.'
            : transcript;
      });

      _showSnack('Transcript ready');
    } catch (e, st) {
      print('TRANSCRIBE ERROR: $e');
      print(st);

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
      print('PLAYBACK ERROR: $e');
    }
  }

  Future<void> _deleteRecording(RecordingItem item) async {
    try {
      final file = File(item.path);
      if (await file.exists()) {
        await file.delete();
      }

      await _storageService.deleteRecording(item.id);
      await _loadRecordings();

      if (!mounted) return;
      _showSnack('Recording deleted');
    } catch (e) {
      _showSnack('Delete failed: $e');
      print('DELETE ERROR: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg2,
        content: Text(
          message,
          style: GoogleFonts.dmSans(color: text, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _generateSummary() async {
    try {
      if (_latestTranscript.trim().isEmpty ||
          _latestTranscript == 'Transcribing...' ||
          _latestTranscript.contains('failed')) {
        _showSnack('No valid transcript available');
        return;
      }

      setState(() {
        _summaryText = 'Generating summary...';
      });

      final summary = await _summaryService.summarizeText(_latestTranscript);

      if (!mounted) return;

      setState(() {
        _summaryText = summary.trim().isEmpty
            ? 'No summary generated.'
            : summary;
      });

      _showSnack('Summary ready');
    } catch (e) {
      setState(() {
        _summaryText = 'Summary failed: $e';
      });

      _showSnack('Summary failed');
    }
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: bg3, shape: BoxShape.circle),
            child: IconButton(
              padding: EdgeInsets.zero,
              splashRadius: 18,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left, color: text2, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Voice Recorder',
              style: GoogleFonts.syne(
                color: text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: text2,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModulePill(String title) {
    final active = selectedModule == title;

    return GestureDetector(
      onTap: () {
        if (isRecording) return;
        setState(() {
          selectedModule = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? teal.withOpacity(0.12) : bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? teal : bg3, width: 1.5),
        ),
        child: Text(
          title,
          style: GoogleFonts.dmSans(
            color: active ? teal : text2,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
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
              color: teal.withOpacity(isRecording ? 1 : 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecordButton() {
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
                      color: coral.withOpacity(opacity),
                      spreadRadius: spread,
                      blurRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? coral.withOpacity(0.20)
                    : teal.withOpacity(0.12),
                border: Border.all(color: isRecording ? coral : teal, width: 2),
              ),
              child: Center(
                child: Text(
                  isRecording ? '⏹️' : '🎙️',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecorderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildWaveform(),
          const SizedBox(height: 14),
          if (isRecording || showAiSection)
            Text(
              _formatTime(seconds),
              style: GoogleFonts.syne(
                color: coral,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (isRecording || showAiSection) const SizedBox(height: 14),
          _buildRecordButton(),
          const SizedBox(height: 14),
          Text(
            isRecording ? 'Recording...' : 'Tap to start recording',
            style: GoogleFonts.dmSans(
              color: isRecording ? coral : text2,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.dmSans(
            color: text3,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptBox({
    required String textValue,
    Color textColor = text2,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg4),
      ),
      child: Text(
        textValue,
        style: GoogleFonts.dmSans(color: textColor, fontSize: 12, height: 1.6),
      ),
    );
  }

  Widget _buildSmallButton({
    required String textValue,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: primary ? 16 : 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: primary ? teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: primary ? null : Border.all(color: bg4, width: 1.5),
        ),
        child: Text(
          textValue,
          style: GoogleFonts.syne(
            color: primary ? Colors.black : text2,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildAiSection() {
    if (!showAiSection) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI Transcript'),
        _buildTranscriptBox(textValue: _latestTranscript),
        _buildSectionTitle('AI Summary'),
        _buildTranscriptBox(textValue: _summaryText, textColor: text),
        if (recordedFilePath != null) ...[
          const SizedBox(height: 8),
          Text(
            recordedFilePath!,
            style: GoogleFonts.dmSans(color: text3, fontSize: 10),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSmallButton(
              textValue: '✨ Summarise',
              primary: true,
              onTap: _generateSummary,
            ),
            const SizedBox(width: 8),
            _buildSmallButton(
              textValue: 'Save to Notes',
              primary: false,
              onTap: () {
                _showSnack('Notes save step comes next');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentRecordingCard(RecordingItem item) {
    final isPlaying = _playingPath == item.path;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bg3),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _togglePlayback(item),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (item.module == 'Software Eng.' ? amber : teal)
                    .withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  isPlaying ? '⏸' : '▶',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.module,
                  style: GoogleFonts.syne(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDurationLabel(item.durationSeconds)} · ${_formatDayLabel(item.createdAt)}',
                  style: GoogleFonts.dmSans(
                    color: text2,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if (item.isTranscribing) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Transcribing...',
                    style: GoogleFonts.dmSans(
                      color: amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (item.transcript != null &&
                    item.transcript!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.transcript!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: text2,
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
            icon: const Icon(Icons.delete_outline, color: text2, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Recent recordings'),
        if (_recentRecordings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bg3),
            ),
            child: Text(
              'No recordings yet',
              style: GoogleFonts.dmSans(color: text2, fontSize: 12),
            ),
          )
        else
          ..._recentRecordings.map(_buildRecentRecordingCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Save to module'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildModulePill('Data Structures'),
                        _buildModulePill('Software Eng.'),
                        _buildModulePill('Database'),
                      ],
                    ),
                    _buildRecorderSection(),
                    _buildAiSection(),
                    _buildRecentRecordingsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
