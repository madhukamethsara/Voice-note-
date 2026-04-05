class QuizPromptBuilder {
  String build({
    required String moduleName,
    required List<String> summaries,
  }) {
    if (summaries.isEmpty) return '';

    final buffer = StringBuffer();

    buffer.writeln('Module: $moduleName');
    buffer.writeln('');
    buffer.writeln('Exam revision summaries:');
    buffer.writeln('');

    for (int i = 0; i < summaries.length; i++) {
      final summary = summaries[i].trim();

      if (summary.isNotEmpty) {
        buffer.writeln('Summary ${i + 1}:');
        buffer.writeln(summary);
        buffer.writeln('');
      }
    }

    return buffer.toString().trim();
  }
}