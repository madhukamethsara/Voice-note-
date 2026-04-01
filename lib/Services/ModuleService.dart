import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/TimetableEntry.dart';

class ModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _modulesRef {
    return _firestore.collection('users').doc(_uid).collection('modules');
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

  Future<void> saveModulesFromTimetable(List<TimetableEntry> entries) async {
    final Set<String> moduleCodes = entries
        .where((entry) {
          final code = entry.moduleCode.toUpperCase().trim();

          return code.isNotEmpty &&
              code != "SPECIAL" &&
              code.startsWith("PUSL") &&
              !_isAssessmentText(entry.rawText);
        })
        .map((entry) => entry.moduleCode.toUpperCase().trim())
        .toSet();

    final batch = _firestore.batch();

    for (final moduleCode in moduleCodes) {
      final docRef = _modulesRef.doc(moduleCode);

      batch.set(docRef, {
        'moduleCode': moduleCode,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<List<String>> getUserModules() async {
    final snapshot = await _modulesRef.get();

    return snapshot.docs
        .map((doc) => (doc.data()['moduleCode'] ?? '').toString())
        .where((code) => code.isNotEmpty)
        .toList();
  }
}