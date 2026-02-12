import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vomi/services/user_location_service.dart';
import 'package:vomi/views/main/journal/journal_entry.dart';

class JournalStorage {
  static const UserLocationService _locationService = UserLocationService();

  static String _key(String uid) => 'journal_entries_$uid';
  static bool _isGuest(String uid) => uid == 'local_user';

  static CollectionReference<Map<String, dynamic>> _entriesRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journal_entries');
  }

  static CollectionReference<Map<String, dynamic>> get _postsRef {
    return FirebaseFirestore.instance.collection('posts');
  }

  static Future<List<JournalEntry>> loadEntries(String uid) async {
    if (!_isGuest(uid)) {
      final snapshot = await _entriesRef(uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          data['createdAt'] = createdAt.toDate().toIso8601String();
        }
        data['id'] = data['id'] ?? doc.id;
        return JournalEntry.fromJson(data);
      }).toList();
    }

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
    if (!_isGuest(uid)) {
      final batch = FirebaseFirestore.instance.batch();
      for (final entry in entries) {
        final ref = _entriesRef(uid).doc(entry.id);
        batch.set(ref, _toFirestore(entry), SetOptions(merge: true));
      }
      await batch.commit();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key(uid), encoded);
  }

  static Future<void> addEntry(String uid, JournalEntry entry) async {
    if (!_isGuest(uid)) {
      await _entriesRef(uid).doc(entry.id).set(_toFirestore(entry));
      if (entry.scope != '비공개') {
        await _postsRef.doc(entry.id).set(_toFirestore(entry));
      }
      await _locationService.markVisitedByName(uid, entry.location);
      return;
    }

    final entries = await loadEntries(uid);
    entries.insert(0, entry);
    await saveEntries(uid, entries);
  }

  static Map<String, dynamic> _toFirestore(JournalEntry entry) {
    final json = entry.toJson();
    json['createdAt'] = Timestamp.fromDate(entry.createdAt);
    return json;
  }
}
