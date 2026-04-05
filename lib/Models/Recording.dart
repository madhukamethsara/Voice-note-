import 'package:cloud_firestore/cloud_firestore.dart';

class RecordingItem {
  final String id;
  final String module;
  final String path;
  final int durationSeconds;
  final DateTime createdAt;
  final String? transcript;
  final String? summary;
  final bool isTranscribing;
  final bool isSummarizing;

  RecordingItem({
    required this.id,
    required this.module,
    required this.path,
    required this.durationSeconds,
    required this.createdAt,
    this.transcript,
    this.summary,
    this.isTranscribing = false,
    this.isSummarizing = false,
  });

  RecordingItem copyWith({
    String? id,
    String? module,
    String? path,
    int? durationSeconds,
    DateTime? createdAt,
    String? transcript,
    String? summary,
    bool? isTranscribing,
    bool? isSummarizing,
  }) {
    return RecordingItem(
      id: id ?? this.id,
      module: module ?? this.module,
      path: path ?? this.path,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      isSummarizing: isSummarizing ?? this.isSummarizing,
    );
  }

  // Local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module,
      'path': path,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
      'transcript': transcript,
      'summary': summary,
      'isTranscribing': isTranscribing,
      'isSummarizing': isSummarizing,
    };
  }

  factory RecordingItem.fromMap(Map<String, dynamic> map) {
    return RecordingItem(
      id: map['id'] ?? '',
      module: map['module'] ?? '',
      path: map['path'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      transcript: map['transcript'],
      summary: map['summary'],
      isTranscribing: map['isTranscribing'] ?? false,
      isSummarizing: map['isSummarizing'] ?? false,
    );
  }

  // Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'module': module,
      'path': path,
      'durationSeconds': durationSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
      'transcript': transcript,
      'summary': summary,
      'isTranscribing': isTranscribing,
      'isSummarizing': isSummarizing,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory RecordingItem.fromFirestore(Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];

    DateTime parsedCreatedAt;
    if (createdAtValue is Timestamp) {
      parsedCreatedAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      parsedCreatedAt = DateTime.parse(createdAtValue);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return RecordingItem(
      id: map['id'] ?? '',
      module: map['module'] ?? '',
      path: map['path'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      createdAt: parsedCreatedAt,
      transcript: map['transcript'],
      summary: map['summary'],
      isTranscribing: map['isTranscribing'] ?? false,
      isSummarizing: map['isSummarizing'] ?? false,
    );
  }
}