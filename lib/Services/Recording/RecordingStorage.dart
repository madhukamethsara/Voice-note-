import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../Models/Recording.dart';

class RecordingStorageService {
  static const String _key = 'saved_recordings';

  Future<List<RecordingItem>> getRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    final List<RecordingItem> items = [];

    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          items.add(RecordingItem.fromMap(decoded));
        } else if (decoded is Map) {
          items.add(
            RecordingItem.fromMap(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (e) {
        print('Failed to parse saved recording: $e');
      }
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveAllRecordings(List<RecordingItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    final rawList = items
        .map((item) => jsonEncode(item.toMap()))
        .toList();

    await prefs.setStringList(_key, rawList);
  }

  Future<void> saveRecording(RecordingItem item) async {
    final items = await getRecordings();

    items.removeWhere((existing) => existing.id == item.id);
    items.insert(0, item);

    await saveAllRecordings(items);
  }

  Future<void> updateRecording(RecordingItem item) async {
    final items = await getRecordings();
    final index = items.indexWhere((existing) => existing.id == item.id);

    if (index != -1) {
      items[index] = item;
    } else {
      items.insert(0, item);
    }

    await saveAllRecordings(items);
  }

  Future<void> deleteRecording(String id) async {
    final items = await getRecordings();

    items.removeWhere((item) => item.id == id);

    await saveAllRecordings(items);
  }

  Future<void> clearAllRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
