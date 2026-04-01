class TimetableEntry {
  final String moduleCode;
  final String degree;
  final String day;
  final String startTime;
  final String endTime;
  final String rawText;
  final int week;
  final String createdBy; 

  TimetableEntry({
    required this.moduleCode,
    required this.degree,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.rawText,
    required this.week,
    required this.createdBy, 
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
      'createdBy': createdBy, 
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
      createdBy: map['createdBy'] ?? '', 
    );
  }

  @override
  String toString() {
    return 'Week $week | $day | $startTime-$endTime | $moduleCode | $degree | $rawText';
  }
}