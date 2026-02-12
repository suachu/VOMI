import 'package:vomi/views/main/list_models.dart';

const List<String> listFilters = ['전체', '근처', '인기', '최신'];

final List<ListItem> mockListItems = [
  ListItem(
    title: '강남 보호소 산책 봉사',
    subtitle: '서울시 강남구 · 1.2km',
    distanceKm: 1.2,
    popularity: 84,
    createdAt: DateTime.parse('2026-02-09'),
    thumbnailAsset: 'assets/images/volunteer/illus_animal1.png',
    region: '서울특별시',
    district: '강남구',
  ),
  ListItem(
    title: '송파 유기견 급식 봉사',
    subtitle: '서울시 송파구 · 2.1km',
    distanceKm: 2.1,
    popularity: 76,
    createdAt: DateTime.parse('2026-02-06'),
    thumbnailAsset: 'assets/images/volunteer/illus_animal2.png',
    region: '서울특별시',
    district: '송파구',
  ),
  ListItem(
    title: '마포 임보센터 청소',
    subtitle: '서울시 마포구 · 4.7km',
    distanceKm: 4.7,
    popularity: 68,
    createdAt: DateTime.parse('2026-02-10'),
    thumbnailAsset: 'assets/images/volunteer/illus_animal3.png',
    region: '서울특별시',
    district: '마포구',
  ),
  ListItem(
    title: '용산 보호묘 케어 지원',
    subtitle: '서울시 용산구 · 3.5km',
    distanceKm: 3.5,
    popularity: 92,
    createdAt: DateTime.parse('2026-02-08'),
    thumbnailAsset: 'assets/images/volunteer/illus_animal4.png',
    region: '서울특별시',
    district: '용산구',
  ),
  ListItem(
    title: '동작 유기견 놀이 봉사',
    subtitle: '서울시 동작구 · 5.4km',
    distanceKm: 5.4,
    popularity: 59,
    createdAt: DateTime.parse('2026-02-11'),
    thumbnailAsset: 'assets/images/volunteer/Error.png',
    region: '서울특별시',
    district: '동작구',
  ),
];
