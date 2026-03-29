class RecordingItem {
  final String id;
  final String module;
  final String path;
  final int durationSeconds;
  final DateTime createdAt;

  RecordingItem({
    required this.id,
    required this.module,
    required this.path,
    required this.durationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module,
      'path': path,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecordingItem.fromMap(Map<String, dynamic> map) {
    return RecordingItem(
      id: map['id'] ?? '',
      module: map['module'] ?? '',
      path: map['path'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
