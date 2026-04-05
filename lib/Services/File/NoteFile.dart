import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Models/NoteFileItem.dart';

class ModuleFileStats {
  final int fileCount;
  final DateTime? latestUpdatedAt;

  ModuleFileStats({
    required this.fileCount,
    this.latestUpdatedAt,
  });
}

class NoteFileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _filesRef(String moduleCode) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('modules')
        .doc(moduleCode)
        .collection('files');
  }

  DocumentReference<Map<String, dynamic>> _moduleRef(String moduleCode) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('modules')
        .doc(moduleCode);
  }

  Future<void> addFile(NoteFileItem item) async {
    final now = FieldValue.serverTimestamp();

    await _filesRef(item.moduleCode).doc(item.id).set({
      ...item.toMap(),
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await _moduleRef(item.moduleCode).set({
      'updatedAt': now,
      'totalFiles': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Stream<List<NoteFileItem>> getFilesByModule(String moduleCode) {
    return _filesRef(moduleCode)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return NoteFileItem.fromMap({
          'id': doc.id,
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

  Stream<ModuleFileStats> getModuleFileStats(String moduleCode) {
    return _filesRef(moduleCode)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      DateTime? latestUpdatedAt;

      if (snapshot.docs.isNotEmpty) {
        final firstDoc = snapshot.docs.first.data();
        final rawUpdatedAt = firstDoc['updatedAt'];
        final rawCreatedAt = firstDoc['createdAt'];

        if (rawUpdatedAt is Timestamp) {
          latestUpdatedAt = rawUpdatedAt.toDate();
        } else if (rawCreatedAt is Timestamp) {
          latestUpdatedAt = rawCreatedAt.toDate();
        }
      }

      return ModuleFileStats(
        fileCount: snapshot.docs.length,
        latestUpdatedAt: latestUpdatedAt,
      );
    });
  }
}