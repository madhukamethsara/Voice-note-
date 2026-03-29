import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:voicenote/Services/FileService.dart';
import 'package:voicenote/Services/ExcelService.dart';
import 'package:voicenote/Services/TimetableService.dart';
import 'package:voicenote/Models/TimetableEntry.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<TimetableScreen> {
  int selectedDayIndex = 0;

  final List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri"];

  final Map<String, List<Map<String, dynamic>>> timetableData = {
    "Mon": [],
    "Tue": [],
    "Wed": [],
    "Thu": [],
    "Fri": [],
  };

  final FileService _fileService = FileService();
  final ExcelService _excelService = ExcelService();
  final TimetableService _timetableService = TimetableService();

  List<TimetableEntry> _firebaseEntries = [];
  List<TimetableEntry> _upcomingEntries = [];

  String _studentDegree = "";
  bool _isLoadingTimetable = false;
  int _currentWeek = 1;

  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _currentWeek = _timetableService.getCurrentAcademicWeek();
    _loadStudentDegree();
  }

  Future<void> _loadStudentDegree() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final degree = (data?['degree'] ?? '').toString().trim();

      if (!mounted) return;

      setState(() {
        _studentDegree = degree;
      });

      if (_studentDegree.isNotEmpty) {
        await _loadFilteredTimetable();
      }

      print("LOGGED_USER_DEGREE → $_studentDegree");
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading student degree: $e"),
          backgroundColor: const Color(0xFF141720),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadTimetable() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final PlatformFile? file = await _fileService.pickExcelFile();

      if (!mounted) return;

      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No file selected"),
            backgroundColor: Color(0xFF141720),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final Uint8List? bytes = _fileService.getFileBytes(file);

      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not read file bytes"),
            backgroundColor: Color(0xFF141720),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _selectedFileName = file.name;
      });

      final entries = _excelService.parseTimetable(bytes, user.uid);

      await _timetableService.saveEntries(entries, user.uid);
      await _loadFilteredTimetable();

      for (final entry in entries) {
        print("PARSED_TIMETABLE → ${entry.toString()}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Parsed, saved & loaded ${entries.length} timetable entries",
          ),
          backgroundColor: const Color(0xFF141720),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error reading Excel: $e"),
          backgroundColor: const Color(0xFF141720),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadFilteredTimetable() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _studentDegree.isEmpty) return;

      setState(() {
        _isLoadingTimetable = true;
      });

      final entries = await _timetableService.getCurrentWeekEntries(_studentDegree, user.uid);
      final upcoming = await _timetableService.getUpcomingEntries(_studentDegree, user.uid);

      if (!mounted) return;

      setState(() {
        _firebaseEntries = entries;
        _upcomingEntries = upcoming;
        _isLoadingTimetable = false;
      });

      print("FILTERED_ENTRIES_COUNT (Week $_currentWeek) → ${entries.length}");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTimetable = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading timetable: $e"),
          backgroundColor: const Color(0xFF141720),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<TimetableEntry> _getEntriesForSelectedDay() {
    final dayMap = {
      "Mon": "Monday",
      "Tue": "Tuesday",
      "Wed": "Wednesday",
      "Thu": "Thursday",
      "Fri": "Friday",
    };

    final selectedDay = dayMap[days[selectedDayIndex]] ?? "Monday";

    return _firebaseEntries.where((entry) => entry.day == selectedDay).toList();
  }

  List<Map<String, dynamic>> _buildDaySessions() {
    final entries = _getEntriesForSelectedDay();

    return entries.map((entry) {
      return {
        "time": entry.startTime.length >= 5
            ? entry.startTime.substring(0, 5)
            : entry.startTime,
        "subject": entry.moduleCode == "SPECIAL"
            ? entry.rawText
            : entry.moduleCode,
        "place":
            "Week ${entry.week} · ${entry.degree} · ${entry.endTime.length >= 5 ? entry.endTime.substring(0, 5) : entry.endTime}",
        "color": _getColorForEntry(entry),
      };
    }).toList();
  }

  Color _getColorForEntry(TimetableEntry entry) {
    final text = entry.rawText.toUpperCase();

    if (text.contains("EXAM")) return const Color(0xFFFF6B6B);
    if (text.contains("COURSEWORK") || text.contains("SUBMISSION")) {
      return const Color(0xFFFFC145);
    }
    if (text.contains("VIVA")) return const Color(0xFFA78BFA);
    if (text.contains("HOLIDAY") ||
        text.contains("POYADAY") ||
        text.contains("STUDY LEAVE") ||
        text.contains("INDEPENDENCE DAY")) {
      return const Color(0xFF60A5FA);
    }

    return const Color(0xFF00E5B0);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = days[selectedDayIndex];
    final sessions = (_studentDegree.isEmpty || _firebaseEntries.isEmpty)
        ? (timetableData[selectedDay] ?? [])
        : _buildDaySessions();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141720),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Timetable (Week $_currentWeek)",
          style: const TextStyle(
            color: Color(0xFFF0F2FF),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUploadCard(),
              const SizedBox(height: 18),
              const Text(
                "Select Day",
                style: TextStyle(
                  color: Color(0xFF8B92B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = selectedDayIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDayIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0x1400E5B0)
                              : const Color(0xFF141720),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E5B0)
                                : const Color(0xFF232840),
                            width: 1.4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            days[index],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00E5B0)
                                  : const Color(0xFF8B92B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "$selectedDay Schedule",
                style: const TextStyle(
                  color: Color(0xFFF0F2FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _isLoadingTimetable
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                          color: Color(0xFF00E5B0),
                        ),
                      ),
                    )
                  : sessions.isEmpty
                      ? _buildEmptyState(selectedDay)
                      : Column(
                          children: sessions.map((session) {
                            return _buildTimeTableRow(
                              time: session["time"],
                              subject: session["subject"],
                              place: session["place"],
                              color: session["color"],
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 22),
              const Text(
                "Upcoming Events (Next 2 Weeks)",
                style: TextStyle(
                  color: Color(0xFFF0F2FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildExamCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF232840)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.upload_file_rounded,
                color: Color(0xFF00E5B0),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                "Upload Timetable",
                style: TextStyle(
                  color: Color(0xFFF0F2FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose your Excel file and later we can read the timetable data and save it to the database.",
            style: TextStyle(
              color: Color(0xFF8B92B8),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (_selectedFileName != null) ...[
            const SizedBox(height: 8),
            Text(
              "Selected: $_selectedFileName",
              style: const TextStyle(
                color: Color(0xFF00E5B0),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploadTimetable,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5B0),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Choose Excel File",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTableRow({
    required String time,
    required String subject,
    required String place,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                time,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF555E7A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF0F2FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8B92B8),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard() {
    if (_upcomingEntries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141720),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x44FF6B6B)),
        ),
        child: const Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "No upcoming events",
                        style: TextStyle(
                          color: Color(0xFFF0F2FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "No exams or submissions in the next 2 weeks.",
                        style: TextStyle(
                          color: Color(0xFF8B92B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Logic to build the list of all upcoming activities
    return Column(
      children: _upcomingEntries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141720),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _getColorForEntry(entry).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.moduleCode == "SPECIAL" ? entry.rawText : entry.moduleCode,
                        style: const TextStyle(
                          color: Color(0xFFF0F2FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${entry.day} · ${entry.startTime}",
                        style: const TextStyle(
                          color: Color(0xFF8B92B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "${entry.week}",
                      style: TextStyle(
                        color: _getColorForEntry(entry),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      "week",
                      style: TextStyle(
                        color: Color(0xFF555E7A),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String currentDay) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232840)),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, color: Color(0xFF8B92B8), size: 30),
          const SizedBox(height: 10),
          Text(
            "No lectures for Week $_currentWeek $currentDay",
            style: const TextStyle(
              color: Color(0xFFF0F2FF),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Wait for data or check if you uploaded the correct timetable.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8B92B8),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}