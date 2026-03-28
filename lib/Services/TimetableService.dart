import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/TimetableEntry.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save fresh timetable:
  /// 1. delete old timetable docs
  /// 2. save new docs
  Future<void> saveEntries(List<TimetableEntry> entries) async {
    await deleteAllEntries();

    final batch = _firestore.batch();

    for (var entry in entries) {
      final doc = _firestore.collection("timetable").doc();
      batch.set(doc, entry.toMap());
    }

    await batch.commit();
  }

  /// Delete every existing timetable entry
  Future<void> deleteAllEntries() async {
    final snapshot = await _firestore.collection("timetable").get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Get all entries
  Future<List<TimetableEntry>> getAllEntries() async {
    final snapshot = await _firestore.collection("timetable").get();

    return snapshot.docs
        .map((doc) => TimetableEntry.fromMap(doc.data()))
        .toList();
  }

  /// Filter entries by student degree
  Future<List<TimetableEntry>> getEntriesByDegree(String studentDegree) async {
    final allEntries = await getAllEntries();

    final student = studentDegree.toUpperCase().replaceAll(" ", "");

    final filtered = allEntries.where((entry) {
      final degreeText = entry.degree.toUpperCase().replaceAll(" ", "");

      if (degreeText == "ALL") return true;

      return degreeText.contains(student);
    }).toList();

    filtered.sort(_compareEntries);
    return filtered;
  }

  /// Get upcoming important entries
  Future<List<TimetableEntry>> getUpcomingEntries(String studentDegree) async {
    final filtered = await getEntriesByDegree(studentDegree);

    final upcoming = filtered.where((entry) {
      final text = entry.rawText.toUpperCase();

      return text.contains("EXAM") ||
          text.contains("COURSEWORK") ||
          text.contains("SUBMISSION") ||
          text.contains("VIVA") ||
          text.contains("STUDY LEAVE") ||
          text.contains("HOLIDAY") ||
          text.contains("POYADAY") ||
          text.contains("INDEPENDENCE DAY");
    }).toList();

    upcoming.sort(_compareEntries);
    return upcoming;
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