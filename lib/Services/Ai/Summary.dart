import 'package:dio/dio.dart';

class SummaryService {
  SummaryService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:3000',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio _dio;

  Future<String> summarizeText(String text) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      throw Exception('Text is empty');
    }

    try {
      final response = await _dio.post(
        '/summarize',
        data: {
          'text': trimmedText,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map && data['summary'] != null) {
          final summary = data['summary'].toString().trim();

          if (summary.isNotEmpty) {
            return summary;
          }
        }
      }

      throw Exception('Invalid summary response');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timed out');
      }

      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server took too long to respond');
      }

      if (e.type == DioExceptionType.sendTimeout) {
        throw Exception('Request took too long to send');
      }

      if (e.response != null) {
        throw Exception(
          'Summary request failed: ${e.response?.statusCode} ${e.response?.statusMessage ?? ''}'
              .trim(),
        );
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to summarize: $e');
    }
  }
}