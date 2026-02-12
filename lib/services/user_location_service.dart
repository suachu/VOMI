import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vomi/views/main/map_places.dart';

class UserLocationService {
  const UserLocationService();

  CollectionReference<Map<String, dynamic>> _locationsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('locations');
  }

  Future<void> seedDefaultLocations(String uid) async {
    final existingSnapshot = await _locationsRef(uid).get();
    final existingIds = existingSnapshot.docs.map((doc) => doc.id).toSet();

    final batch = FirebaseFirestore.instance.batch();
    var hasChanges = false;
    for (final place in mapPlaces) {
      if (existingIds.contains(place.id)) {
        continue;
      }
      final ref = _locationsRef(uid).doc(place.id);
      batch.set(ref, {
        'id': place.id,
        'title': place.title,
        'latitude': place.latitude,
        'longitude': place.longitude,
        'visited': place.visited,
        'source': 'default',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasChanges = true;
    }
    if (hasChanges) {
      await batch.commit();
    }
  }

  Future<void> markVisitedByName(String uid, String locationName) async {
    final normalized = locationName.trim();
    if (normalized.isEmpty) return;
    final id = 'journal_${_safeId(normalized)}';
    await _locationsRef(uid).doc(id).set({
      'id': id,
      'title': normalized,
      'visited': true,
      'source': 'journal',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<MapPlace>> loadMapPlaces(String uid) async {
    await seedDefaultLocations(uid);
    final snapshot = await _locationsRef(uid).get();
    final docsById = {
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };

    return mapPlaces.map((defaultPlace) {
      final data = docsById[defaultPlace.id];
      if (data == null) return defaultPlace;
      return defaultPlace.copyWith(
        visited: data['visited'] as bool? ?? defaultPlace.visited,
      );
    }).toList();
  }

  String _safeId(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
