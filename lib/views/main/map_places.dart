class MapPlace {
  const MapPlace({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.visited,
  });

  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final bool visited;

  MapPlace copyWith({
    String? id,
    String? title,
    double? latitude,
    double? longitude,
    bool? visited,
  }) {
    return MapPlace(
      id: id ?? this.id,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visited: visited ?? this.visited,
    );
  }
}

// Edit this list to control which places appear on the map.
// visited: true  -> uses 32.png
// visited: false -> uses 31.png
const List<MapPlace> mapPlaces = <MapPlace>[
  MapPlace(
    id: 'animal shelther',
    title: '포항 동물보호센터',
    latitude: 36.1456523,
    longitude: 129.3327358,
    visited: true,
  ),
  MapPlace(
    id: 'pohang beach',
    title: '포항 영일대 해수욕장',
    latitude: 36.0561507,
    longitude: 129.3781717,
    visited: true,
  ),
  MapPlace(
    id: "pohang children'shome",
    title: '포항 선린애육원',
    latitude: 36.0718301,
    longitude: 129.4000994,
    visited: true,
  ),
];
