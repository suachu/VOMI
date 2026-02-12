import 'package:flutter/foundation.dart';
import 'package:vomi/views/main/journal/journal_entry.dart';

class PostVisibilityRegistry {
  static final ValueNotifier<Set<String>> hiddenPostIds =
      ValueNotifier<Set<String>>(<String>{});
  static final ValueNotifier<Set<String>> hiddenPostKeys =
      ValueNotifier<Set<String>>(<String>{});

  static void hide(String postId) {
    final next = <String>{...hiddenPostIds.value, postId};
    hiddenPostIds.value = next;
  }

  static void show(String postId) {
    if (!hiddenPostIds.value.contains(postId)) return;
    final next = <String>{...hiddenPostIds.value}..remove(postId);
    hiddenPostIds.value = next;
  }

  static String keyFromEntry(JournalEntry entry) {
    return '${entry.authorUid}|${entry.title}|${entry.location}|${entry.content}|${entry.createdAt.millisecondsSinceEpoch}';
  }

  static String keyFromRaw({
    required String authorUid,
    required String title,
    required String location,
    required String content,
    required int createdAtMillis,
  }) {
    return '$authorUid|$title|$location|$content|$createdAtMillis';
  }

  static void hideEntry(JournalEntry entry) {
    hide(entry.id);
    final next = <String>{...hiddenPostKeys.value, keyFromEntry(entry)};
    hiddenPostKeys.value = next;
  }

  static void showEntry(JournalEntry entry) {
    show(entry.id);
    if (!hiddenPostKeys.value.contains(keyFromEntry(entry))) return;
    final next = <String>{...hiddenPostKeys.value}..remove(keyFromEntry(entry));
    hiddenPostKeys.value = next;
  }
}
