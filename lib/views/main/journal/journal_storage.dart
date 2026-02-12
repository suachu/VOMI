import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vomi/views/main/journal/journal_entry.dart';

class JournalStorage {
  static String _key(String uid) => 'journal_entries_$uid';

  static Future<List<JournalEntry>> loadEntries(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final entries = decoded
        .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  static Future<void> saveEntries(String uid, List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key(uid), encoded);
  }

  static Future<void> addEntry(String uid, JournalEntry entry) async {
    final entries = await loadEntries(uid);
    entries.insert(0, entry);
    await saveEntries(uid, entries);
  }
}
