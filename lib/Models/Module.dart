class Module {
  final String moduleCode;
  final String moduleName;
  final String lecturer;

  Module({
    required this.moduleCode,
    required this.moduleName,
    required this.lecturer,
  });

  Map<String, dynamic> toMap() {
    return {
      "moduleCode": moduleCode,
      "moduleName": moduleName,
      "lecturer": lecturer,
    };
  }
}