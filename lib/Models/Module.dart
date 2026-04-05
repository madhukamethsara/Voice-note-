class Module {
  final String moduleCode;
  final String moduleName;
  final String lecturer;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalFiles;

  Module({
    required this.moduleCode,
    required this.moduleName,
    required this.lecturer,
    this.createdAt,
    this.updatedAt,
    this.totalFiles = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      "moduleCode": moduleCode,
      "moduleName": moduleName,
      "lecturer": lecturer,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
      "totalFiles": totalFiles,
    };
  }

  factory Module.fromMap(Map<String, dynamic> map) {
    return Module(
      moduleCode: map["moduleCode"] ?? "",
      moduleName: map["moduleName"] ?? "",
      lecturer: map["lecturer"] ?? "",
      createdAt: map["createdAt"] != null
          ? DateTime.tryParse(map["createdAt"])
          : null,
      updatedAt: map["updatedAt"] != null
          ? DateTime.tryParse(map["updatedAt"])
          : null,
      totalFiles: map["totalFiles"] ?? 0,
    );
  }
}