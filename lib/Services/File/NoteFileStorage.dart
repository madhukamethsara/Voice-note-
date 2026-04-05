import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicenote/Models/NoteFileItem.dart';

class NoteFileStorageService {
  static const String _key = 'saved_note_files';

  Future<List<NoteFileItem>> getFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    final List<NoteFileItem> items = [];

    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          items.add(NoteFileItem.fromMap(decoded));
        } else if (decoded is Map) {
          items.add(NoteFileItem.fromMap(Map<String, dynamic>.from(decoded)));
        }
      } catch (e) {
        print('Failed to parse saved note file: $e');
      }
    }

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> saveAllFiles(List<NoteFileItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    final rawList = items
        .map((item) => jsonEncode(item.toMap()))
        .toList();

    await prefs.setStringList(_key, rawList);
  }

  Future<void> saveFile(NoteFileItem item) async {
    final items = await getFiles();

    final index = items.indexWhere((existing) => existing.id == item.id);

    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }

    await saveAllFiles(items);
  }

  Future<void> deleteFile(String id) async {
    final items = await getFiles();
    items.removeWhere((item) => item.id == id);
    await saveAllFiles(items);
  }

  Future<NoteFileItem?> getFileById(String id) async {
    final items = await getFiles();

    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<NoteFileItem>> getFilesByModule(String moduleName) async {
    final items = await getFiles();

    return items
        .where((item) => item.moduleName == moduleName)
        .toList();
  }

  Future<void> clearAllFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}