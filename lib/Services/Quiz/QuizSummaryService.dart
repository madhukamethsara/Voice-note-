import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizSummaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged in user found.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _recordingsCollection {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('recordings');
  }

  Future<List<Map<String, dynamic>>> _getValidSummaryDocs() async {
    try {
      print('QUIZ_DEBUG: current uid = $_uid');
      print('QUIZ_DEBUG: reading from users/$_uid/recordings');

      final snapshot = await _recordingsCollection.get();

      print('QUIZ_DEBUG: total recording docs = ${snapshot.docs.length}');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('QUIZ_DEBUG DOC ${doc.id}: $data');
      }

      final validDocs = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .where((data) {
            final module = (data['module'] ?? '').toString().trim();
            final summary = (data['summary'] ?? '').toString().trim();

            return module.isNotEmpty && summary.isNotEmpty;
          })
          .toList();

      print('QUIZ_DEBUG: valid summary docs = ${validDocs.length}');
      return validDocs;
    } catch (e, st) {
      print('QUIZ_DEBUG ERROR in _getValidSummaryDocs: $e');
      print(st);
      rethrow;
    }
  }

  Future<List<String>> getAvailableModules() async {
    try {
      final docs = await _getValidSummaryDocs();

      final modules = docs
          .map((item) => item['module'].toString().trim())
          .toSet()
          .toList();

      modules.sort();

      print('QUIZ_DEBUG: available modules = $modules');
      return modules;
    } catch (e, st) {
      print('QUIZ_DEBUG ERROR in getAvailableModules: $e');
      print(st);
      rethrow;
    }
  }

  Future<List<String>> getSummariesByModule(String moduleName) async {
    try {
      print('QUIZ_DEBUG: requested module = "$moduleName"');

      final docs = await _getValidSummaryDocs();

      final summaries = docs
          .where(
            (item) =>
                item['module'].toString().trim().toLowerCase() ==
                moduleName.trim().toLowerCase(),
          )
          .map((item) => item['summary'].toString().trim())
          .where((summary) => summary.isNotEmpty)
          .toList();

      print('QUIZ_DEBUG: summaries found = ${summaries.length}');
      return summaries;
    } catch (e, st) {
      print('QUIZ_DEBUG ERROR in getSummariesByModule: $e');
      print(st);
      rethrow;
    }
  }
}