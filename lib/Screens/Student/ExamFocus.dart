import 'package:flutter/material.dart';
import 'package:voicenote/Models/QuizQuestion.dart';
import 'package:voicenote/Services/QuizPromptBuilder.dart';
import 'package:voicenote/Services/QuizService.dart';
import 'package:voicenote/Services/QuizSummaryService.dart';
import 'package:voicenote/Services/QuizAttemptService.dart';
import 'package:voicenote/Services/FlashcardService.dart';
import '../../Theme/theme_helper.dart';

class ExamFocusScreen extends StatefulWidget {
  const ExamFocusScreen({super.key});

  @override
  State<ExamFocusScreen> createState() => _ExamFocusScreenState();
}

class _ExamFocusScreenState extends State<ExamFocusScreen> {
  final QuizSummaryService _quizSummaryService = QuizSummaryService();
  final QuizPromptBuilder _quizPromptBuilder = QuizPromptBuilder();
  final QuizService _quizService = QuizService();
  final QuizAttemptService _quizAttemptService = QuizAttemptService();
  final FlashcardService _flashcardService = FlashcardService();

  bool _isLoadingModules = true;
  bool _isGeneratingQuiz = false;
  String? _errorMessage;

  String? _selectedModule;
  List<String> _modules = [];
  List<QuizQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    try {
      final modules = await _quizSummaryService.getAvailableModules();

      if (!mounted) return;

      setState(() {
        _modules = modules;
        _selectedModule = modules.isNotEmpty ? modules.first : null;
        _isLoadingModules = false;
        _errorMessage = modules.isEmpty ? 'No summaries found yet.' : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingModules = false;
        _errorMessage = 'Failed to load modules: $e';
      });
    }
  }

  Future<void> _generateExamPack() async {
    if (_selectedModule == null) {
      setState(() {
        _errorMessage = 'Please select a module first.';
      });
      return;
    }

    setState(() {
      _isGeneratingQuiz = true;
      _errorMessage = null;
      _questions = [];
    });

    try {
      final summaries = await _quizSummaryService.getSummariesByModule(
        _selectedModule!,
      );

      if (summaries.isEmpty) {
        throw Exception('No summaries found for $_selectedModule');
      }

      final combinedText = _quizPromptBuilder.build(
        moduleName: _selectedModule!,
        summaries: summaries,
      );

      if (combinedText.trim().isEmpty) {
        throw Exception('No valid summary content found.');
      }

      final questions = await _quizService.generateQuiz(
        moduleName: _selectedModule!,
        combinedSummaryText: combinedText,
        questionCount: 10,
      );

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isGeneratingQuiz = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGeneratingQuiz = false;
        _errorMessage = 'Failed to generate quiz: $e';
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_selectedModule == null || _questions.isEmpty) return;

    for (final q in _questions) {
      q.isCorrect = q.selectedAnswer == q.correctAnswer;
    }

    setState(() {});

    try {
      final attemptId = await _quizAttemptService.saveQuizAttempt(
        module: _selectedModule!,
        questions: _questions,
      );

      await _flashcardService.saveFlashcardsFromWrongAnswers(
        module: _selectedModule!,
        sourceAttemptId: attemptId,
        questions: _questions,
      );

      final wrongCount = _questions.where((q) => q.isCorrect == false).length;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wrongCount == 0
                ? 'Great job! All answers are correct.'
                : '$wrongCount flashcards created from weak areas.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save quiz result: $e')));
    }
  }

  int get _score => _questions.where((q) => q.isCorrect == true).length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const red = Colors.redAccent;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
        title: Text('Exam Focus', style: TextStyle(color: colors.text)),
      ),
      body: _isLoadingModules
          ? Center(child: CircularProgressIndicator(color: colors.teal))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bg2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.bg4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate Exam Questions',
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a module and create 20 quiz questions from saved Firestore summaries.',
                          style: TextStyle(color: colors.text2, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedModule,
                          dropdownColor: colors.bg2,
                          decoration: InputDecoration(
                            labelText: 'Select Module',
                            labelStyle: TextStyle(color: colors.text2),
                            filled: true,
                            fillColor: colors.bg,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.bg4),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.teal),
                            ),
                          ),
                          style: TextStyle(color: colors.text),
                          iconEnabledColor: colors.text,
                          items: _modules
                              .map(
                                (module) => DropdownMenuItem<String>(
                                  value: module,
                                  child: Text(
                                    module,
                                    style: TextStyle(color: colors.text),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (module) {
                            setState(() {
                              _selectedModule = module;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isGeneratingQuiz
                                ? null
                                : _generateExamPack,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.teal,
                              foregroundColor: colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isGeneratingQuiz
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Generate 20 Questions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _questions.isEmpty
                      ? Center(
                          child: Text(
                            'No quiz generated yet.',
                            style: TextStyle(color: colors.text2, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final q = _questions[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.bg2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.bg4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}. ${q.question}',
                                    style: TextStyle(
                                      color: colors.text,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...q.options.map(
                                    (option) => RadioListTile<String>(
                                      value: option,
                                      groupValue: q.selectedAnswer,
                                      onChanged: (selectedOption) {
                                        setState(() {
                                          q.selectedAnswer = selectedOption;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: colors.teal,
                                      title: Text(
                                        option,
                                        style: TextStyle(color: colors.text),
                                      ),
                                    ),
                                  ),
                                  if (q.isCorrect != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      q.isCorrect == true ? 'Correct' : 'Wrong',
                                      style: TextStyle(
                                        color: q.isCorrect == true
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Correct Answer: ${q.correctAnswer}',
                                      style: TextStyle(color: colors.text2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Explanation: ${q.explanation}',
                                      style: TextStyle(color: colors.text2),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (_questions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        if (_questions.any((q) => q.isCorrect != null))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Score: $_score / ${_questions.length}',
                                style: TextStyle(
                                  color: colors.teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitQuiz,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.teal,
                              foregroundColor: colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit Quiz',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
