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

  List<TimetableEntry> parseTimetable(Uint8List bytes, String uid) {
    final excel = Excel.decodeBytes(bytes);
    final List<TimetableEntry> entries = [];

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

      final weekMatch = RegExp(
        r'Week\s+(\d+)',
        caseSensitive: false,
      ).firstMatch(col1);
      if (weekMatch != null) {
        currentWeek = int.tryParse(weekMatch.group(1) ?? "0") ?? 0;
        continue;
      }

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
          uid: uid,
        );

        entries.addAll(parsedEntries);
      }
    }

    return entries;
  }

  Map<String, Map<String, dynamic>> parseModuleDetails(
    Uint8List bytes,
    String studentDegree,
  ) {
    final excel = Excel.decodeBytes(bytes);
    final Map<String, Map<String, dynamic>> moduleDetails = {};

    Sheet? modulesSheet;
    for (final entry in excel.tables.entries) {
      final name = entry.key.toLowerCase().trim();
      if (name == "modules") {
        modulesSheet = entry.value;
        break;
      }
    }

    if (modulesSheet == null) {
      print("Modules sheet not found.");
      return moduleDetails;
    }

    final sheet = modulesSheet;

    int codeCol = -1;
    int nameCol = -1;
    int lecturerCol = -1;
    int sem1Col = -1;
    int sem2Col = -1;
    bool headerFound = false;

    for (int i = 0; i < sheet.maxRows; i++) {
      final row = sheet.row(i);

      final values = row
          .map((c) => (c?.value?.toString() ?? "").trim())
          .toList();

    
      //final rowText = values.join(" ").toUpperCase();

      // Find header row once
      if (!headerFound &&
          values.contains("Module Code") &&
          values.contains("Module Name")) {
        for (int j = 0; j < values.length; j++) {
          final val = values[j];
          if (val == "Module Code") codeCol = j;
          if (val == "Module Name") nameCol = j;
          if (val == "Lecturer Name") lecturerCol = j;
          if (val == "Semester 1") sem1Col = j;
          if (val == "Semester 2") sem2Col = j;
        }
        headerFound = true;
        continue;
      }

      if (!headerFound) continue;
      if (codeCol == -1 || nameCol == -1) continue;
      if (codeCol >= row.length) continue;

      final moduleCode = row[codeCol]?.value?.toString().trim() ?? "";
      if (!moduleCode.toUpperCase().startsWith("PUSL")) continue;

      final moduleName = nameCol < row.length
          ? row[nameCol]?.value?.toString().trim() ?? ""
          : "";

      final lecturerName = lecturerCol != -1 && lecturerCol < row.length
          ? row[lecturerCol]?.value?.toString().trim() ?? ""
          : "";

      String semester = "";
      final sem1 = sem1Col != -1 && sem1Col < row.length
          ? row[sem1Col]?.value?.toString().trim() ?? ""
          : "";
      final sem2 = sem2Col != -1 && sem2Col < row.length
          ? row[sem2Col]?.value?.toString().trim() ?? ""
          : "";

      if (sem2.isNotEmpty) {
        semester = "Semester 2";
      } else if (sem1.isNotEmpty) {
        semester = "Semester 1";
      }

      moduleDetails[moduleCode.toUpperCase().trim()] = {
        'moduleCode': moduleCode.toUpperCase().trim(),
        'moduleName': moduleName,
        'lecturerName': lecturerName,
        'semester': semester,
      };
    }

    //print("PARSED MODULE DETAILS -> ${moduleDetails.keys.toList()}");
    //print("PUSL2020 -> ${moduleDetails['PUSL2020']}");
    //print("PUSL2023 -> ${moduleDetails['PUSL2023']}");

    return moduleDetails;
  }

  List<TimetableEntry> _extractEntriesFromCell({
    required String cellText,
    required String day,
    required String startTime,
    required String endTime,
    required int week,
    required String uid,
  }) {
    final List<TimetableEntry> results = [];

    final upper = cellText.toUpperCase();

    if (!upper.contains("PUSL")) {
      final degreeMatch = RegExp(r'\(([^)]*)\)').firstMatch(cellText);
      final extractedDegree = degreeMatch?.group(1)?.trim() ?? "";

      final isGlobalSpecial =
          upper.contains("HOLIDAY") ||
          upper.contains("POYA") ||
          upper.contains("STUDY LEAVE") ||
          upper.contains("INDEPENDENCE DAY");

      results.add(
        TimetableEntry(
          moduleCode: "SPECIAL",
          degree: isGlobalSpecial
              ? "ALL"
              : (extractedDegree.isEmpty ? "ALL" : extractedDegree),
          day: day,
          startTime: startTime,
          endTime: endTime,
          rawText: cellText,
          week: week,
          createdBy: uid,
        ),
      );
      return results;
    }

    final lines = cellText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

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
      final moduleMatch = RegExp(
        r'PUSL\s?\d+',
        caseSensitive: false,
      ).firstMatch(chunk);
      final degreeMatch = RegExp(r'\(([^)]*)\)').firstMatch(chunk);

      final moduleCode =
          moduleMatch?.group(0)?.replaceAll(" ", "") ?? "UNKNOWN";
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
          createdBy: uid,
        ),
      );
    }

    return results;
  }

  bool _isTime(String value) {
    return RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(value);
  }
}
