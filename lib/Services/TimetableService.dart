import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/TimetableEntry.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final DateTime semesterStart = DateTime(2026, 2, 2);

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _timetableRef {
    return _firestore.collection('users').doc(_uid).collection('timetable');
  }

  int getCurrentAcademicWeek() {
    final now = DateTime.now();
    if (now.isBefore(semesterStart)) return 1;

    final difference = now.difference(semesterStart).inDays;
    int week = (difference / 7).floor() + 1;

    return week > 0 ? week : 1;
  }

  List<TimetableEntry> filterEntriesForDegree(
    List<TimetableEntry> entries,
    String studentDegree,
  ) {
    final student = studentDegree.toUpperCase().trim();

    final filtered = entries.where((entry) {
      final degreeText = entry.degree.toUpperCase().trim();

      if (degreeText == "ALL") return true;

      final parts = degreeText
          .split('/')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      return parts.contains(student);
    }).toList();

    filtered.sort(_compareEntries);
    return filtered;
  }

  Future<void> saveEntries(List<TimetableEntry> entries) async {
    await deleteUserEntries();

    final batch = _firestore.batch();

    for (var entry in entries) {
      final doc = _timetableRef.doc();
      batch.set(doc, entry.toMap());
    }

    await batch.commit();
  }

  Future<void> deleteUserEntries() async {
    final snapshot = await _timetableRef.get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<List<TimetableEntry>> getAllEntries() async {
    final snapshot = await _timetableRef.get();

    final entries = snapshot.docs
        .map((doc) => TimetableEntry.fromMap(doc.data()))
        .toList();

    entries.sort(_compareEntries);
    return entries;
  }

  Future<List<TimetableEntry>> getCurrentWeekEntries() async {
    final int currentWeek = getCurrentAcademicWeek();
    final allEntries = await getAllEntries();

    return allEntries.where((entry) => entry.week == currentWeek).toList();
  }

  Future<Set<String>> getUserModuleCodes() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('modules')
        .get();

    return snapshot.docs
        .map(
          (doc) => (doc.data()['moduleCode'] ?? '')
              .toString()
              .toUpperCase()
              .trim(),
        )
        .where((code) => code.isNotEmpty)
        .toSet();
  }

  List<String> extractModuleCodes(String text) {
    final regex = RegExp(r'PUSL\d{4}', caseSensitive: false);

    return regex
        .allMatches(text.toUpperCase())
        .map((match) => match.group(0)!)
        .toSet()
        .toList();
  }

  bool _isAssessmentText(String text) {
    final upper = text.toUpperCase();
    return upper.contains("EXAM") ||
        upper.contains("VIVA") ||
        upper.contains("COURSEWORK") ||
        upper.contains("SUBMISSION") ||
        upper.contains("PRESENTATION") ||
        upper.contains("TEST");
  }

  bool _isTrueGlobalSpecial(TimetableEntry entry) {
    final text = entry.rawText.toUpperCase();
    final moduleCode = entry.moduleCode.toUpperCase().trim();

    return moduleCode == "SPECIAL" &&
        (text.contains("HOLIDAY") ||
            text.contains("POYA") ||
            text.contains("STUDY LEAVE") ||
            text.contains("INDEPENDENCE DAY"));
  }

  Future<List<TimetableEntry>> getUpcomingEntries() async {
    final int currentWeek = getCurrentAcademicWeek();
    final allEntries = await getAllEntries();
    final userModules = await getUserModuleCodes();

    final upcoming = allEntries.where((entry) {
      final moduleCode = entry.moduleCode.toUpperCase().trim();
      final rawText = entry.rawText.toUpperCase();

      final bool isAssessment = _isAssessmentText(rawText);
      final bool isWithinRange =
          entry.week >= currentWeek && entry.week <= (currentWeek + 10);

      if (!isAssessment || !isWithinRange) {
        return false;
      }

      if (_isTrueGlobalSpecial(entry)) {
        return true;
      }

      final modulesInText = extractModuleCodes(entry.rawText);

      final bool belongsToUser = modulesInText.isNotEmpty
          ? modulesInText.any((code) => userModules.contains(code))
          : userModules.contains(moduleCode);

      return belongsToUser;
    }).toList();

    final Map<String, TimetableEntry> uniqueMap = {};
    for (final entry in upcoming) {
      final key =
          "${entry.rawText.toUpperCase().trim()}|${entry.week}";
      uniqueMap[key] = entry;
    }

    final uniqueUpcoming = uniqueMap.values.toList();
    uniqueUpcoming.sort(_compareEntries);

    return uniqueUpcoming;
  }

  int _compareEntries(TimetableEntry a, TimetableEntry b) {
    if (a.week != b.week) {
      return a.week.compareTo(b.week);
    }

    final dayOrder = {
      "Monday": 1,
      "Tuesday": 2,
      "Wednesday": 3,
      "Thursday": 4,
      "Friday": 5,
    };

    final aDay = dayOrder[a.day] ?? 99;
    final bDay = dayOrder[b.day] ?? 99;

    if (aDay != bDay) {
      return aDay.compareTo(bDay);
    }

    return a.startTime.compareTo(b.startTime);
  }
}