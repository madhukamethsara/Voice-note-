import 'dart:io';
import 'package:dio/dio.dart';

class TranscriptionService {
  final Dio _dio = Dio();

  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<String> transcribeAudio(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }

    final fileName = file.path.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '$baseUrl/transcribe',
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
      ),
    );


    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map && data['transcript'] != null) {
        return data['transcript'].toString();
      }
    }

    throw Exception('Failed to transcribe audio');
  }
}