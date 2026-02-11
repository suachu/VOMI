class ListItem {
  final String title;
  final String subtitle;
  final double distanceKm;
  final int popularity;
  final DateTime createdAt;
  final String thumbnailAsset;

  const ListItem({
    required this.title,
    required this.subtitle,
    required this.distanceKm,
    required this.popularity,
    required this.createdAt,
    required this.thumbnailAsset,
  });
}
