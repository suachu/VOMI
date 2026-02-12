import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikedVolunteer {
  const LikedVolunteer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnailAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final String thumbnailAsset;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'thumbnailAsset': thumbnailAsset,
  };

  factory LikedVolunteer.fromJson(Map<String, dynamic> json) {
    return LikedVolunteer(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      subtitle: (json['subtitle'] as String?) ?? '',
      thumbnailAsset: (json['thumbnailAsset'] as String?) ?? '',
    );
  }
}

class LikedVolunteerService {
  static const String _storageKey = 'liked_volunteers_v1';
  static bool _loaded = false;

  static final ValueNotifier<List<LikedVolunteer>> likedItems =
      ValueNotifier<List<LikedVolunteer>>(const []);
  static final ValueNotifier<int> likedCount = ValueNotifier<int>(0);

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _loaded = true;
      likedItems.value = const [];
      likedCount.value = 0;
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .map((e) => LikedVolunteer.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.trim().isNotEmpty)
          .toList();
      likedItems.value = items;
      likedCount.value = items.length;
      _loaded = true;
    } catch (_) {
      likedItems.value = const [];
      likedCount.value = 0;
      _loaded = true;
    }
  }

  static bool isLikedSync(String id) {
    return likedItems.value.any((item) => item.id == id);
  }

  static Future<bool> isLiked(String id) async {
    await ensureLoaded();
    return isLikedSync(id);
  }

  static Future<void> toggle(LikedVolunteer item) async {
    await ensureLoaded();
    final current = List<LikedVolunteer>.from(likedItems.value);
    final existingIndex = current.indexWhere((e) => e.id == item.id);

    if (existingIndex >= 0) {
      current.removeAt(existingIndex);
    } else {
      current.insert(0, item);
    }

    await _save(current);
  }

  static Future<void> _save(List<LikedVolunteer> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    likedItems.value = List<LikedVolunteer>.unmodifiable(items);
    likedCount.value = items.length;
  }
}
