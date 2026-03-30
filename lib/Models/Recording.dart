class RecordingItem {
  final String id;
  final String module;
  final String path;
  final int durationSeconds;
  final DateTime createdAt;
  final String? transcript;
  final bool isTranscribing;

  RecordingItem({
    required this.id,
    required this.module,
    required this.path,
    required this.durationSeconds,
    required this.createdAt,
    this.transcript,
    this.isTranscribing = false,
  });

  RecordingItem copyWith({
    String? id,
    String? module,
    String? path,
    int? durationSeconds,
    DateTime? createdAt,
    String? transcript,
    bool? isTranscribing,
  }) {
    return RecordingItem(
      id: id ?? this.id,
      module: module ?? this.module,
      path: path ?? this.path,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      transcript: transcript ?? this.transcript,
      isTranscribing: isTranscribing ?? this.isTranscribing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module,
      'path': path,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
      'transcript': transcript,
      'isTranscribing': isTranscribing,
    };
  }

  factory RecordingItem.fromMap(Map<String, dynamic> map) {
    return RecordingItem(
      id: (map['id'] ?? '').toString(),
      module: (map['module'] ?? '').toString(),
      path: (map['path'] ?? '').toString(),
      durationSeconds: _parseInt(map['durationSeconds']),
      createdAt: _parseDateTime(map['createdAt']),
      transcript: map['transcript']?.toString(),
      isTranscribing: map['isTranscribing'] == true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
    }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
