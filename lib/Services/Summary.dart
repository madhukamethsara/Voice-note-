import 'package:dio/dio.dart';

class SummaryService {
  final Dio _dio = Dio();

  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<String> summarizeText(String text) async {
    final response = await _dio.post(
      '$baseUrl/summarize',
      data: {
        'text': text,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map && data['summary'] != null) {
        return data['summary'].toString();
      }
    }

    throw Exception('Failed to summarize');
  }
}