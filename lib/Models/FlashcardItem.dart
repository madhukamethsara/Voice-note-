class FlashcardItem {
  final String id;
  final String module;
  final String question;
  final String answer;
  final String correctAnswer;
  final String sourceAttemptId;
  final DateTime createdAt;
  final String type;

  FlashcardItem({
    required this.id,
    required this.module,
    required this.question,
    required this.answer,
    required this.correctAnswer,
    required this.sourceAttemptId,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'module': module,
      'question': question,
      'answer': answer,
      'correctAnswer': correctAnswer,
      'sourceAttemptId': sourceAttemptId,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
    };
  }

  factory FlashcardItem.fromMap(String id, Map<String, dynamic> map) {
    return FlashcardItem(
      id: id,
      module: map['module'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      correctAnswer: map['correctAnswer'] ?? '',
      sourceAttemptId: map['sourceAttemptId'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      type: map['type'] ?? 'weak_area',
    );
  }
}