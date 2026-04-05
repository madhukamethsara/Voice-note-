import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class FileService {
  Future<PlatformFile?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.first;
    }

    return null;
  }

  Uint8List? getFileBytes(PlatformFile file) {
    return file.bytes;
  }
}