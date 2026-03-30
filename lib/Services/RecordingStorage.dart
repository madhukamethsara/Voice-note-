import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../Models/Recording.dart';

class RecordingStorageService {
  static const String _key = 'saved_recordings';

  Future<List<RecordingItem>> getRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    final items = rawList
        .map((e) => RecordingItem.fromMap(jsonDecode(e)))
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveRecording(RecordingItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    rawList.insert(0, jsonEncode(item.toMap()));
    await prefs.setStringList(_key, rawList);
  }

  Future<void> deleteRecording(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    final items = rawList
        .map((e) => RecordingItem.fromMap(jsonDecode(e)))
        .where((item) => item.id != id)
        .map((item) => jsonEncode(item.toMap()))
        .toList();

    await prefs.setStringList(_key, items);
  }
}
