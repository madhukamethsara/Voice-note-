import 'package:dio/dio.dart';
import 'package:voicenote/Models/QuizQuestion.dart';

class QuizService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<List<QuizQuestion>> generateQuiz({
    required String moduleName,
    required String combinedSummaryText,
    int questionCount = 10,
  }) async {
    try {
      print('QUIZ_API: moduleName = $moduleName');
      print('QUIZ_API: questionCount = $questionCount');
      print('QUIZ_API: content length = ${combinedSummaryText.length}');

      final response = await _dio.post(
        '/generate-daily-quiz',
        data: {
          'moduleName': moduleName,
          'content': combinedSummaryText,
          'questionCount': questionCount,
        },
      );

      print('QUIZ_API: statusCode = ${response.statusCode}');
      print('QUIZ_API: response data = ${response.data}');

      final data = response.data;

      if (data == null || data['mcqs'] == null) {
        throw Exception('Invalid MCQ response');
      }

      return (data['mcqs'] as List)
          .map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      print('QUIZ_API DIO ERROR: ${e.message}');
      print('QUIZ_API DIO RESPONSE: ${e.response?.data}');
      throw Exception('Server error: ${e.message}');
    } catch (e) {
      print('QUIZ_API GENERAL ERROR: $e');
      rethrow;
    }
  }
}