import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:voicenote/Models/TimetableEntry.dart';

class ExcelService {
  void debugExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null) continue;

      print("====== SHEET: $sheetName ======");

      for (int i = 0; i < sheet.maxRows; i++) {
        final row = sheet.row(i);

        bool isEmpty = true;
        for (final cell in row) {
          final value = cell?.value?.toString() ?? "";
          if (value.trim().isNotEmpty) {
            isEmpty = false;
            break;
          }
        }

        if (isEmpty) continue;

        String rowText = "";
        for (final cell in row) {
          rowText += "${cell?.value?.toString() ?? 'null'} | ";
        }

        print("ROW $i → $rowText");
      }
    }
  }

  List<TimetableEntry> parseTimetable(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final List<TimetableEntry> entries = [];

    // find the real timetable sheet
    Sheet? timetableSheet;
    for (final entry in excel.tables.entries) {
      final name = entry.key.toLowerCase();
      if (name.contains("timetable") || name.contains("y2s2")) {
        timetableSheet = entry.value;
        break;
      }
    }

    if (timetableSheet == null) {
      print("No timetable sheet found.");
      return [];
    }

    final sheet = timetableSheet;

    // find the row with Monday-Friday headers
    int dayHeaderRowIndex = -1;

    for (int i = 0; i < sheet.maxRows; i++) {
      final row = sheet.row(i);

      final rowValues = row
          .map((c) => (c?.value?.toString() ?? "").toLowerCase().trim())
          .toList();

      if (rowValues.contains("monday") &&
          rowValues.contains("tuesday") &&
          rowValues.contains("wednesday")) {
        dayHeaderRowIndex = i;
        break;
      }
    }

    if (dayHeaderRowIndex == -1) {
      print("Could not find day header row.");
      return [];
    }

    final headerRow = sheet.row(dayHeaderRowIndex);

    final Map<String, int> dayColumns = {};
    for (int j = 0; j < headerRow.length; j++) {
      final value = headerRow[j]?.value?.toString().trim() ?? "";

      if (value == "Monday") dayColumns["Monday"] = j;
      if (value == "Tuesday") dayColumns["Tuesday"] = j;
      if (value == "Wednesday") dayColumns["Wednesday"] = j;
      if (value == "Thursday") dayColumns["Thursday"] = j;
      if (value == "Friday") dayColumns["Friday"] = j;
    }

    int currentWeek = 0;

    for (int i = dayHeaderRowIndex + 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);

      final col1 = row.length > 1 ? row[1]?.value?.toString().trim() ?? "" : "";
      final col2 = row.length > 2 ? row[2]?.value?.toString().trim() ?? "" : "";

      // detect week rows like "Week 1", "Week 2"
      final weekMatch = RegExp(r'Week\s+(\d+)', caseSensitive: false).firstMatch(col1);
      if (weekMatch != null) {
        currentWeek = int.tryParse(weekMatch.group(1) ?? "0") ?? 0;
        continue;
      }

      // only process rows that look like time rows
      if (!_isTime(col1) || !_isTime(col2)) continue;

      final startTime = col1;
      final endTime = col2;

      for (final day in dayColumns.keys) {
        final colIndex = dayColumns[day]!;
        if (colIndex >= row.length) continue;

        final cellText = row[colIndex]?.value?.toString().trim() ?? "";
        if (cellText.isEmpty) continue;

        final parsedEntries = _extractEntriesFromCell(
          cellText: cellText,
          day: day,
          startTime: startTime,
          endTime: endTime,
          week: currentWeek,
        );

        entries.addAll(parsedEntries);
      }
    }

    return entries;
  }

  List<TimetableEntry> _extractEntriesFromCell({
    required String cellText,
    required String day,
    required String startTime,
    required String endTime,
    required int week,
  }) {
    final List<TimetableEntry> results = [];

    // special events without module code
    final upper = cellText.toUpperCase();

    if (!upper.contains("PUSL")) {
      results.add(
        TimetableEntry(
          moduleCode: "SPECIAL",
          degree: "ALL",
          day: day,
          startTime: startTime,
          endTime: endTime,
          rawText: cellText,
          week: week,
        ),
      );
      return results;
    }

    // split multiline entries
    final lines = cellText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // combine lines smartly into module chunks
    final List<String> chunks = [];
    String buffer = "";

    for (final line in lines) {
      if (RegExp(r'PUSL\s?\d+', caseSensitive: false).hasMatch(line)) {
        if (buffer.isNotEmpty) {
          chunks.add(buffer.trim());
        }
        buffer = line;
      } else {
        if (buffer.isNotEmpty) {
          buffer += " $line";
        } else {
          buffer = line;
        }
      }
    }

    if (buffer.isNotEmpty) {
      chunks.add(buffer.trim());
    }

    for (final chunk in chunks) {
      final moduleMatch =
          RegExp(r'PUSL\s?\d+', caseSensitive: false).firstMatch(chunk);
      final degreeMatch = RegExp(r'\(([^)]*)\)').firstMatch(chunk);

      final moduleCode = moduleMatch?.group(0)?.replaceAll(" ", "") ?? "UNKNOWN";
      final degree = degreeMatch?.group(1)?.trim() ?? "ALL";

      results.add(
        TimetableEntry(
          moduleCode: moduleCode,
          degree: degree,
          day: day,
          startTime: startTime,
          endTime: endTime,
          rawText: chunk,
          week: week,
        ),
      );
    }

    return results;
  }

  bool _isTime(String value) {
    return RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(value);
  }
}