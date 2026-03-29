import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/TimetableEntry.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveEntries(List<TimetableEntry> entries, String uid) async {
    
    await deleteUserEntries(uid);

    final batch = _firestore.batch();

    for (var entry in entries) {
      final doc = _firestore.collection("timetable").doc();
      batch.set(doc, entry.toMap());
    }

    await batch.commit();
  }

  Future<void> deleteUserEntries(String uid) async {
    final snapshot = await _firestore
        .collection("timetable")
        .where("createdBy", isEqualTo: uid)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<List<TimetableEntry>> getEntriesByDegree(String studentDegree, String uid) async {
    final snapshot = await _firestore
        .collection("timetable")
        .where("createdBy", isEqualTo: uid)
        .get();

    final allEntries = snapshot.docs
        .map((doc) => TimetableEntry.fromMap(doc.data()))
        .toList();

    final student = studentDegree.toUpperCase().replaceAll(" ", "");

    final filtered = allEntries.where((entry) {
      final degreeText = entry.degree.toUpperCase().replaceAll(" ", "");

      if (degreeText == "ALL") return true;

      return degreeText.contains(student);
    }).toList();

    filtered.sort(_compareEntries);
    return filtered;
  }

  Future<List<TimetableEntry>> getUpcomingEntries(String studentDegree, String uid) async {
    final filtered = await getEntriesByDegree(studentDegree, uid);

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