import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicenote/Models/QuizQuestion.dart';

class QuizAttemptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged in user found.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _attemptsCollection {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('quiz_attempts');
  }

  Future<String> saveQuizAttempt({
    required String module,
    required List<QuizQuestion> questions,
  }) async {
    final correctCount = questions.where((q) => q.isCorrect == true).length;
    final wrongCount = questions.where((q) => q.isCorrect == false).length;
    final totalQuestions = questions.length;

    final docRef = _attemptsCollection.doc();

    await docRef.set({
      'module': module,
      'score': correctCount,
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'createdAt': DateTime.now().toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    });

    return docRef.id;
  }
}