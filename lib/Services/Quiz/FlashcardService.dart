import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicenote/Models/FlashcardItem.dart';
import 'package:voicenote/Models/QuizQuestion.dart';

class FlashcardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged in user found.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _flashcardsCollection {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('flashcards');
  }

  Future<void> saveFlashcardsFromWrongAnswers({
    required String module,
    required String sourceAttemptId,
    required List<QuizQuestion> questions,
  }) async {
    final wrongQuestions =
        questions.where((q) => q.isCorrect == false).toList();

    final batch = _firestore.batch();

    for (final q in wrongQuestions) {
      final docRef = _flashcardsCollection.doc();

      batch.set(docRef, {
        'module': module,
        'question': q.question,
        'answer': q.explanation,
        'correctAnswer': q.correctAnswer,
        'sourceAttemptId': sourceAttemptId,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'weak_area',
      });
    }

    await batch.commit();
  }

  Future<List<FlashcardItem>> getFlashcards() async {
    final snapshot = await _flashcardsCollection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FlashcardItem.fromMap(doc.id, doc.data()))
        .toList();
  }
}