class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  String? selectedAnswer;
  bool? isCorrect;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.selectedAnswer,
    this.isCorrect,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
    };
  }
}