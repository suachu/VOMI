import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  static Future<void> _deleteDuplicatePostDocsByEntryId(
    String entryId, {
    String? exceptDocId,
  }) async {
    final query = await _postsRef.where('id', isEqualTo: entryId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in query.docs) {
      if (exceptDocId != null && doc.id == exceptDocId) continue;
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static bool _isSamePost(Map<String, dynamic> data, JournalEntry entry) {
    final dataId = (data['id'] as String?) ?? '';
    if (dataId == entry.id) return true;

    final authorUid = (data['authorUid'] as String?) ?? '';
    final title = (data['title'] as String?) ?? '';
    final location = (data['location'] as String?) ?? '';
    final content = (data['content'] as String?) ?? '';
    return authorUid == entry.authorUid &&
        title == entry.title &&
        location == entry.location &&
        content == entry.content;
  }

  static Future<void> _deleteRelatedPostDocs(
    String uid,
    JournalEntry entry, {
    String? exceptDocId,
  }) async {
    final query = await _postsRef.where('authorUid', isEqualTo: uid).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in query.docs) {
      if (exceptDocId != null && doc.id == exceptDocId) continue;
      final data = Map<String, dynamic>.from(doc.data());
      if (_isSamePost(data, entry)) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  static String _entrySignature(JournalEntry entry) {
    return '${entry.title}|${entry.location}|${entry.content}|${entry.createdAt.millisecondsSinceEpoch}';
  }

  static String _postSignature(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    int createdAtMillis = 0;
    if (createdAt is Timestamp) {
      createdAtMillis = createdAt.millisecondsSinceEpoch;
    } else if (createdAt is String) {
      createdAtMillis = DateTime.tryParse(createdAt)?.millisecondsSinceEpoch ?? 0;
    }
    return '${(data['title'] as String?) ?? ''}|${(data['location'] as String?) ?? ''}|${(data['content'] as String?) ?? ''}|$createdAtMillis';
  }

  static Future<void> cleanupDanglingPostsForUser({
    required String uid,
    Set<String> legacyAuthorNames = const {},
  }) async {
    if (_isGuest(uid)) return;

    final entries = await loadEntries(uid);
    final entryIds = entries.map((e) => e.id).toSet();
    final entrySignatures = entries.map(_entrySignature).toSet();

    Future<void> cleanupQuery(Query<Map<String, dynamic>> query) async {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await query.get();
      } on FirebaseException catch (e, st) {
        // Skip cleanup if security rules reject this query shape.
        debugPrint('Skipping dangling post cleanup query: ${e.code} ${e.message}');
        debugPrintStack(stackTrace: st);
        return;
      }
      final batch = FirebaseFirestore.instance.batch();
      var hasDeletes = false;
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final authorUid = (data['authorUid'] as String?) ?? '';
        if (authorUid != uid) {
          continue;
        }
        final postId = ((data['id'] as String?)?.trim().isNotEmpty ?? false)
            ? (data['id'] as String).trim()
            : doc.id;
        final postSignature = _postSignature(data);
        final keep = entryIds.contains(postId) || entrySignatures.contains(postSignature);
        if (!keep) {
          batch.delete(doc.reference);
          hasDeletes = true;
        }
      }
      if (!hasDeletes) return;
      await batch.commit();
    }

    await cleanupQuery(_postsRef.where('authorUid', isEqualTo: uid));
    // NOTE:
    // Legacy authorName-only cleanup can fail under Firestore rules because
    // that query may include posts the current user cannot read.
    // Keep the parameter for call-site compatibility.
    if (legacyAuthorNames.isNotEmpty) {
      debugPrint('Skipping legacy authorName cleanup for uid=$uid');
    }
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

  static Future<void> updateEntry(String uid, JournalEntry entry) async {
    if (!_isGuest(uid)) {
      await _entriesRef(uid).doc(entry.id).set(_toFirestore(entry));
      if (entry.scope != '비공개') {
        await _postsRef.doc(entry.id).set(_toFirestore(entry));
        await _deleteDuplicatePostDocsByEntryId(
          entry.id,
          exceptDocId: entry.id,
        );
        await _deleteRelatedPostDocs(
          uid,
          entry,
          exceptDocId: entry.id,
        );
      } else {
        await _postsRef.doc(entry.id).delete().catchError((_) {});
        await _deleteDuplicatePostDocsByEntryId(entry.id);
        await _deleteRelatedPostDocs(uid, entry);
      }
      return;
    }

    final entries = await loadEntries(uid);
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx == -1) return;
    entries[idx] = entry;
    await saveEntries(uid, entries);
  }

  static Future<void> deleteEntry(String uid, JournalEntry entry) async {
    if (!_isGuest(uid)) {
      await _entriesRef(uid).doc(entry.id).delete().catchError((_) {});
      await _postsRef.doc(entry.id).delete().catchError((_) {});
      await _deleteDuplicatePostDocsByEntryId(entry.id);
      await _deleteRelatedPostDocs(uid, entry);
      return;
    }

    final entries = await loadEntries(uid);
    entries.removeWhere((e) => e.id == entry.id);
    await saveEntries(uid, entries);
  }

  static Map<String, dynamic> _toFirestore(JournalEntry entry) {
    final json = entry.toJson();
    json['createdAt'] = Timestamp.fromDate(entry.createdAt);
    return json;
  }
}
