import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/Recording.dart';

class RecordingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _recordingsRef {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('recordings');
  }

  Future<void> saveRecording(RecordingItem item) async {
    await _recordingsRef.doc(item.id).set(item.toFirestore());
  }

  Future<void> updateRecording(RecordingItem item) async {
    await _recordingsRef.doc(item.id).set(item.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteRecording(String id) async {
    await _recordingsRef.doc(id).delete();
  }

  Future<List<RecordingItem>> getRecordings() async {
    final snapshot = await _recordingsRef
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => RecordingItem.fromFirestore(doc.data()))
        .toList();
  }
}