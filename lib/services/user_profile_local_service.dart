import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileLocalData {
  const UserProfileLocalData({
    required this.name,
    required this.appId,
    required this.phone,
    required this.address,
    required this.photoPath,
  });

  final String name;
  final String appId;
  final String phone;
  final String address;
  final String photoPath;
}

class UserProfileLocalService {
  const UserProfileLocalService();
  static final ValueNotifier<int> profileChanged = ValueNotifier<int>(0);

  String _key(String uid, String field) => 'profile_${uid}_$field';

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    final suffix = List.generate(8, (_) => chars[rand.nextInt(chars.length)])
        .join();
    return 'vomi_$suffix';
  }

  Future<UserProfileLocalData> ensure(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = user.uid;

    final savedName = prefs.getString(_key(uid, 'name'));
    final savedId = prefs.getString(_key(uid, 'app_id'));
    final savedPhone = prefs.getString(_key(uid, 'phone'));
    final savedAddress = prefs.getString(_key(uid, 'address'));
    final savedPhotoPath = prefs.getString(_key(uid, 'photo_path'));

    final fallbackName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : '이름 없음';
    final data = UserProfileLocalData(
      name: (savedName?.trim().isNotEmpty ?? false) ? savedName!.trim() : fallbackName,
      appId: (savedId?.trim().isNotEmpty ?? false) ? savedId!.trim() : _generateRandomId(),
      phone: (savedPhone?.trim().isNotEmpty ?? false) ? savedPhone!.trim() : '010-1234-5678',
      address: savedAddress ?? '',
      photoPath: savedPhotoPath ?? '',
    );

    await prefs.setString(_key(uid, 'name'), data.name);
    await prefs.setString(_key(uid, 'app_id'), data.appId);
    await prefs.setString(_key(uid, 'phone'), data.phone);
    await prefs.setString(_key(uid, 'address'), data.address);
    await prefs.setString(_key(uid, 'photo_path'), data.photoPath);
    return data;
  }

  Future<void> saveName(User user, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final name = value.trim();
    await prefs.setString(_key(user.uid, 'name'), name);
    try {
      await user.updateDisplayName(name);
    } catch (_) {}
    await _syncAuthorName(user.uid, name);
    profileChanged.value = profileChanged.value + 1;
  }

  Future<void> _syncAuthorName(String uid, String name) async {
    final db = FirebaseFirestore.instance;
    final entriesSnapshot = await db
        .collection('users')
        .doc(uid)
        .collection('journal_entries')
        .get();
    for (final doc in entriesSnapshot.docs) {
      await doc.reference.set({'authorName': name}, SetOptions(merge: true));
    }

    final postsSnapshot = await db
        .collection('posts')
        .where('authorUid', isEqualTo: uid)
        .get();
    for (final doc in postsSnapshot.docs) {
      await doc.reference.set({'authorName': name}, SetOptions(merge: true));
    }
  }

  Future<void> saveAppId(User user, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(user.uid, 'app_id'), value.trim());
  }

  Future<void> savePhone(User user, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(user.uid, 'phone'), value.trim());
  }

  Future<void> saveAddress(User user, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(user.uid, 'address'), value.trim());
  }

  Future<void> savePhotoPath(User user, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(user.uid, 'photo_path'), value);
  }
}
