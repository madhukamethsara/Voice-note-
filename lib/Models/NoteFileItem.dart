import 'Recording.dart';

class NoteFileItem {
  final String id;
  final String title;
  final String moduleName;
  final String moduleCode;
  final String type;
  final String? audioPath;
  final String? transcript;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteFileItem({
    required this.id,
    required this.title,
    required this.moduleName,
    required this.moduleCode,
    required this.type,
    this.audioPath,
    this.transcript,
    this.summary,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteFileItem copyWith({
    String? id,
    String? title,
    String? moduleName,
    String? moduleCode,
    String? type,
    String? audioPath,
    String? transcript,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteFileItem(
      id: id ?? this.id,
      title: title ?? this.title,
      moduleName: moduleName ?? this.moduleName,
      moduleCode: moduleCode ?? this.moduleCode,
      type: type ?? this.type,
      audioPath: audioPath ?? this.audioPath,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'moduleName': moduleName,
      'moduleCode': moduleCode,
      'type': type,
      'audioPath': audioPath,
      'transcript': transcript,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteFileItem.fromMap(Map<String, dynamic> map) {
    return NoteFileItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      moduleName: map['moduleName'] ?? '',
      moduleCode: map['moduleCode'] ?? '',
      type: map['type'] ?? '',
      audioPath: map['audioPath'],
      transcript: map['transcript'],
      summary: map['summary'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  RecordingItem toRecordingItem() {
    return RecordingItem(
      id: id,
      module: moduleName,
      path: audioPath ?? '',
      durationSeconds: 0,
      createdAt: createdAt,
      transcript: transcript,
      summary: summary,
      isTranscribing: false,
      isSummarizing: false,
    );
  }
}