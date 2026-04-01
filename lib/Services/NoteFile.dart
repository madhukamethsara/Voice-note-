import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Models/NoteFileItem.dart';

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

  Future<void> addFile(NoteFileItem item) async {
    await _filesRef(item.moduleCode).doc(item.id).set(item.toMap());

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('modules')
        .doc(item.moduleCode)
        .set({
      'updatedAt': FieldValue.serverTimestamp(),
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