import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Models/Module.dart';
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
    final filteredEntries = entries.where((entry) {
      final code = entry.moduleCode.toUpperCase().trim();

      return code.isNotEmpty &&
          code != "SPECIAL" &&
          code.startsWith("PUSL") &&
          !_isAssessmentText(entry.rawText);
    }).toList();

    final Map<String, TimetableEntry> uniqueModules = {};

    for (final entry in filteredEntries) {
      final code = entry.moduleCode.toUpperCase().trim();
      if (!uniqueModules.containsKey(code)) {
        uniqueModules[code] = entry;
      }
    }

    final batch = _firestore.batch();

    for (final item in uniqueModules.entries) {
      final moduleCode = item.key;
      final docRef = _modulesRef.doc(moduleCode);

      batch.set(
        docRef,
        {
          'moduleCode': moduleCode,
          'moduleName': '',
          'lecturerName': '',
          'semester': '',
          'totalFiles': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> updateModuleDetails(
    Map<String, Map<String, dynamic>> moduleDetails,
  ) async {
    if (moduleDetails.isEmpty) return;

    final snapshot = await _modulesRef.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final moduleCode = doc.id.toUpperCase().trim();

      if (!moduleDetails.containsKey(moduleCode)) continue;

      batch.set(
        doc.reference,
        {
          'moduleCode': moduleCode,
          'moduleName': moduleDetails[moduleCode]!['moduleName'] ?? '',
          'lecturerName': moduleDetails[moduleCode]!['lecturerName'] ?? '',
          'semester': moduleDetails[moduleCode]!['semester'] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<List<Module>> getUserModules() async {
    final snapshot =
        await _modulesRef.orderBy('updatedAt', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Module.fromMap({
        ...data,
        'createdAt': data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
            : data['createdAt'],
        'updatedAt': data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['updatedAt'],
      });
    }).toList();
  }

  Stream<List<Module>> getUserModulesStream() {
    return _modulesRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return Module.fromMap({
          ...data,
          'createdAt': data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
              : data['createdAt'],
          'updatedAt': data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
              : data['updatedAt'],
        });
      }).toList();
    });
  }
}