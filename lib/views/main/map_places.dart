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
}

// Edit this list to control which places appear on the map.
// visited: true  -> uses 32.png
// visited: false -> uses 31.png
const List<MapPlace> mapPlaces = <MapPlace>[
  MapPlace(
    id: 'beach',
    title: '바다',
    latitude: 36.086936,
    longitude: 129.432869,
    visited: true,
  ),
  MapPlace(
    id: 'moutain',
    title: '산',
    latitude: 36.096504,
    longitude: 129.389529,
    visited: false,
  ),
];
