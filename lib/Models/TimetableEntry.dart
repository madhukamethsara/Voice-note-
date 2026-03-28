class TimetableEntry {
  final String moduleCode;
  final String degree;
  final String day;
  final String startTime;
  final String endTime;
  final String rawText;
  final int week;

  TimetableEntry({
    required this.moduleCode,
    required this.degree,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.rawText,
    required this.week,
  });

  Map<String, dynamic> toMap() {
    return {
      'moduleCode': moduleCode,
      'degree': degree,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'rawText': rawText,
      'week': week,
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      moduleCode: map['moduleCode'] ?? '',
      degree: map['degree'] ?? '',
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      rawText: map['rawText'] ?? '',
      week: map['week'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Week $week | $day | $startTime-$endTime | $moduleCode | $degree | $rawText';
  }
}