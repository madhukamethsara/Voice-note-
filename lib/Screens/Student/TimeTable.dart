import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicenote/Services/File/ModuleService.dart';
import 'package:voicenote/Services/File/FileService.dart';
import 'package:voicenote/Services/ExcelService.dart';
import 'package:voicenote/Services/TimetableService.dart';
import 'package:voicenote/Models/TimetableEntry.dart';
import 'package:voicenote/Theme/theme_helper.dart';

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
  final ModuleService _moduleService = ModuleService();

  List<TimetableEntry> _firebaseEntries = [];
  List<TimetableEntry> _upcomingEntries = [];
  List<String> _assignedModules = [];

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

      print("LOGGED_USER_DEGREE -> $_studentDegree");
    } catch (e) {
      if (!mounted) return;

      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading student degree: $e"),
          backgroundColor: colors.bg2,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<List<String>> _loadAssignedModules(String uid) async {
    try {
      final List<String> modules = [];

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        final assignedModulesField = data?['assignedModules'];
        if (assignedModulesField is List) {
          modules.addAll(
            assignedModulesField
                .map((e) => e.toString().trim().toUpperCase())
                .where((e) => e.isNotEmpty),
          );
        }

        final modulesField = data?['modules'];
        if (modulesField is List) {
          modules.addAll(
            modulesField
                .map((e) => e.toString().trim().toUpperCase())
                .where((e) => e.isNotEmpty),
          );
        }
      }

      if (modules.isEmpty) {
        final assignedSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('assignedModules')
            .get();

        if (assignedSnapshot.docs.isNotEmpty) {
          modules.addAll(
            assignedSnapshot.docs.map((doc) {
              final data = doc.data();
              return (data['moduleCode'] ?? '')
                  .toString()
                  .trim()
                  .toUpperCase();
            }).where((e) => e.isNotEmpty),
          );
        }
      }

      if (modules.isEmpty) {
        final moduleSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('modules')
            .get();

        if (moduleSnapshot.docs.isNotEmpty) {
          modules.addAll(
            moduleSnapshot.docs.map((doc) {
              final data = doc.data();
              return (data['moduleCode'] ?? doc.id)
                  .toString()
                  .trim()
                  .toUpperCase();
            }).where((e) => e.isNotEmpty),
          );
        }
      }

      final uniqueModules = modules.toSet().toList();
      print("ASSIGNED_MODULES_FROM_FIRESTORE -> $uniqueModules");
      return uniqueModules;
    } catch (e) {
      print("Error loading assigned modules: $e");
      return [];
    }
  }

  Future<void> _uploadTimetable() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (_studentDegree.isEmpty) {
        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Student degree not found"),
            backgroundColor: colors.bg2,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final PlatformFile? file = await _fileService.pickExcelFile();

      if (!mounted) return;

      if (file == null) {
        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No file selected"),
            backgroundColor: colors.bg2,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final Uint8List? bytes = _fileService.getFileBytes(file);

      if (bytes == null) {
        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Could not read file bytes"),
            backgroundColor: colors.bg2,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _selectedFileName = file.name;
      });

      final entries = _excelService.parseTimetable(bytes, user.uid);

      final filteredEntries = _timetableService.filterEntriesForDegree(
        entries,
        _studentDegree,
      );

      print("USER DEGREE -> $_studentDegree");
      print("TOTAL PARSED -> ${entries.length}");
      print("TOTAL FILTERED -> ${filteredEntries.length}");

      for (final entry in filteredEntries) {
        print("SAVING -> ${entry.degree} | ${entry.moduleCode}");
      }

      await _timetableService.saveEntries(filteredEntries);
      await _moduleService.saveModulesFromTimetable(filteredEntries);

      final moduleDetails = _excelService.parseModuleDetails(
        bytes,
        _studentDegree,
      );
      await _moduleService.updateModuleDetails(moduleDetails);

      await _loadFilteredTimetable();

      if (!mounted) return;
      final colors = context.colors;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Parsed, filtered, saved & loaded ${filteredEntries.length} timetable entries",
          ),
          backgroundColor: colors.bg2,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final colors = context.colors;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error reading Excel: $e"),
          backgroundColor: colors.bg2,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _matchesAssignedModules(TimetableEntry entry, List<String> assignedModules) {
    final moduleCode = entry.moduleCode.trim().toUpperCase();
    final raw = entry.rawText.trim().toUpperCase();

    if (moduleCode == "SPECIAL") return true;
    if (assignedModules.contains(moduleCode)) return true;

    for (final module in assignedModules) {
      if (raw.contains(module)) {
        return true;
      }
    }

    return false;
  }

  int _dayOrder(String day) {
    switch (day.trim().toUpperCase()) {
      case "MONDAY":
        return 1;
      case "TUESDAY":
        return 2;
      case "WEDNESDAY":
        return 3;
      case "THURSDAY":
        return 4;
      case "FRIDAY":
        return 5;
      case "SATURDAY":
        return 6;
      case "SUNDAY":
        return 7;
      default:
        return 99;
    }
  }

  Future<void> _loadFilteredTimetable() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _studentDegree.isEmpty) return;

      setState(() {
        _isLoadingTimetable = true;
      });

      final assignedModules = await _loadAssignedModules(user.uid);
      final entries = await _timetableService.getCurrentWeekEntries();
      final upcoming = await _timetableService.getUpcomingEntries();

      final filteredEntries = entries
          .where((entry) => _matchesAssignedModules(entry, assignedModules))
          .toList();

      final filteredUpcoming = upcoming
          .where((entry) => _matchesAssignedModules(entry, assignedModules))
          .toList();

      filteredUpcoming.sort((a, b) {
        final weekCompare = a.week.compareTo(b.week);
        if (weekCompare != 0) return weekCompare;

        final dayCompare = _dayOrder(a.day).compareTo(_dayOrder(b.day));
        if (dayCompare != 0) return dayCompare;

        return a.startTime.compareTo(b.startTime);
      });

      if (!mounted) return;

      setState(() {
        _assignedModules = assignedModules;
        _firebaseEntries = filteredEntries;
        _upcomingEntries = filteredUpcoming;
        _isLoadingTimetable = false;
      });

      print("ASSIGNED_MODULES -> $_assignedModules");
      print(
        "FILTERED_ENTRIES_COUNT (Week $_currentWeek) -> ${filteredEntries.length}",
      );
      print(
        "FILTERED_UPCOMING_COUNT -> ${filteredUpcoming.length}",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTimetable = false;
      });

      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading timetable: $e"),
          backgroundColor: colors.bg2,
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

    return _firebaseEntries.where((entry) {
      final matchesDay = entry.day == selectedDay;
      final matchesModules = _matchesAssignedModules(entry, _assignedModules);
      return matchesDay && matchesModules;
    }).toList();
  }

  List<Map<String, dynamic>> _buildDaySessions() {
    final entries = _getEntriesForSelectedDay();

    return entries.map((entry) {
      return {
        "time": entry.startTime.length >= 5
            ? entry.startTime.substring(0, 5)
            : entry.startTime,
        "subject": entry.moduleCode.trim().toUpperCase() == "SPECIAL"
            ? entry.rawText
            : entry.moduleCode,
        "place":
            "Week ${entry.week} · ${entry.degree} · ${entry.endTime.length >= 5 ? entry.endTime.substring(0, 5) : entry.endTime}",
        "color": _getColorForEntry(entry),
      };
    }).toList();
  }

  Color _getColorForEntry(TimetableEntry entry) {
    final colors = context.colors;
    final text = entry.rawText.toUpperCase();

    if (text.contains("EXAM")) return colors.coral;
    if (text.contains("COURSEWORK") || text.contains("SUBMISSION")) {
      return colors.amber;
    }
    if (text.contains("VIVA")) return colors.purple;
    if (text.contains("HOLIDAY") ||
        text.contains("POYADAY") ||
        text.contains("STUDY LEAVE") ||
        text.contains("INDEPENDENCE DAY")) {
      return colors.blue;
    }

    return colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedDay = days[selectedDayIndex];
    final sessions = (_studentDegree.isEmpty || _firebaseEntries.isEmpty)
        ? (timetableData[selectedDay] ?? [])
        : _buildDaySessions();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg2,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Timetable (Week $_currentWeek)",
          style: TextStyle(
            color: colors.text,
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
              Text(
                "Select Day",
                style: TextStyle(
                  color: colors.text2,
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
                              ? colors.teal.withOpacity(0.08)
                              : colors.bg2,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? colors.teal : colors.bg4,
                            width: 1.4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            days[index],
                            style: TextStyle(
                              color: isSelected ? colors.teal : colors.text2,
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
                style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _isLoadingTimetable
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                          color: colors.teal,
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
              Text(
                "Upcoming Exams, Vivas & Deadlines",
                style: TextStyle(
                  color: colors.text,
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
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.bg4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upload_file_rounded,
                color: colors.teal,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                "Upload Timetable",
                style: TextStyle(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Choose your Excel file and later we can read the timetable data and save it to the database.",
            style: TextStyle(
              color: colors.text2,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (_selectedFileName != null) ...[
            const SizedBox(height: 8),
            Text(
              "Selected: $_selectedFileName",
              style: TextStyle(
                color: colors.teal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_assignedModules.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "Your modules: ${_assignedModules.join(', ')}",
              style: TextStyle(
                color: colors.text2,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploadTimetable,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.teal,
                foregroundColor: colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Choose Excel File",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
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
    final colors = context.colors;

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
                style: TextStyle(
                  color: colors.text3,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: color, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text2,
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
    final colors = context.colors;

    if (_upcomingEntries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.bg4),
        ),
        child: Text(
          "No upcoming exams, vivas, or deadlines 🎉",
          style: TextStyle(
            color: colors.text2,
            fontSize: 12,
          ),
        ),
      );
    }

    return Column(
      children: _upcomingEntries.map((entry) {
        final weeksLeft = entry.week - _currentWeek;

        double progress = 1 - (weeksLeft / 6);
        progress = progress.clamp(0.0, 1.0);

        Color progressColor;
        if (entry.rawText.toUpperCase().contains("VIVA")) {
          progressColor = colors.purple;
        } else if (weeksLeft > 4) {
          progressColor = colors.teal;
        } else if (weeksLeft > 2) {
          progressColor = colors.amber;
        } else {
          progressColor = colors.coral;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bg2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: progressColor.withOpacity(0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.rawText.trim(),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${entry.day} · ${entry.startTime}",
                  style: TextStyle(
                    color: colors.text2,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: colors.bg4,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  weeksLeft <= 0
                      ? "This week"
                      : "$weeksLeft week${weeksLeft == 1 ? "" : "s"} left",
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String currentDay) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg4),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: colors.text2,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            "No lectures for Week $_currentWeek $currentDay",
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _assignedModules.isEmpty
                ? "No assigned modules found for this user."
                : "Only your assigned modules are shown here.",
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
}