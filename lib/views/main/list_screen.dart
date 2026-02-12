import 'package:flutter/material.dart';
import 'package:vomi/views/main/list/list_mock_data.dart';
import 'package:vomi/views/main/list_detail_screen.dart';
import 'package:vomi/views/main/list/widgets/list_filter_chips.dart';
import 'package:vomi/views/main/list/widgets/list_results_view.dart';
import 'package:vomi/views/main/list/widgets/list_search_field.dart';
import 'package:vomi/views/main/list_models.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String _selectedFilter = listFilters.first;
  String _searchKeyword = '';
  String _selectedRegion = '전체';
  String _selectedDistrict = '전체';

  List<ListItem> get _visibleItems {
    final String keyword = _searchKeyword.trim().toLowerCase();

    final filteredByKeyword = mockListItems.where((item) {
      final regionMatch =
          _selectedRegion == '전체' || item.region == _selectedRegion;
      final districtMatch =
          _selectedDistrict == '전체' || item.district == _selectedDistrict;
      if (!regionMatch || !districtMatch) {
        return false;
      }
      if (keyword.isEmpty) {
        return true;
      }
      final title = item.title.toLowerCase();
      final subtitle = item.subtitle.toLowerCase();
      return title.contains(keyword) || subtitle.contains(keyword);
    }).toList();

    switch (_selectedFilter) {
      case '근처':
        filteredByKeyword.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case '인기':
        filteredByKeyword.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case '최신':
        filteredByKeyword.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case '전체':
        break;
    }

    return filteredByKeyword;
  }

  List<String> get _regions {
    final values = mockListItems.map((e) => e.region).toSet().toList()..sort();
    return ['전체', ...values.where((e) => e.isNotEmpty)];
  }

  List<String> _districtsFor(String region) {
    if (region == '전체') return ['전체'];
    final values =
        mockListItems
            .where((e) => e.region == region)
            .map((e) => e.district)
            .toSet()
            .toList()
          ..sort();
    return ['전체', ...values.where((e) => e.isNotEmpty)];
  }

  String get _locationFilterLabel {
    if (_selectedRegion == '전체') return '전체';
    if (_selectedDistrict == '전체') return _selectedRegion;
    return '$_selectedRegion $_selectedDistrict';
  }

  Future<void> _openLocationFilterSheet() async {
    String tempRegion = _selectedRegion;
    String tempDistrict = _selectedDistrict;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final districts = _districtsFor(tempRegion);
            if (!districts.contains(tempDistrict)) {
              tempDistrict = '전체';
            }
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.68,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        children: [
                          const Text(
                            '필터',
                            style: TextStyle(
                              fontFamily: 'Pretendard Variable',
                              fontSize: 32 / 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                tempRegion = '전체';
                                tempDistrict = '전체';
                              });
                            },
                            child: const Text(
                              '필터 초기화',
                              style: TextStyle(
                                fontFamily: 'Pretendard Variable',
                                fontSize: 14,
                                color: Color(0xFFB1B3B9),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 28),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E8EB)),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                16,
                                16,
                                16,
                              ),
                              itemCount: _regions.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final region = _regions[index];
                                final isSelected = tempRegion == region;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      tempRegion = region;
                                      tempDistrict = '전체';
                                    });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          region,
                                          style: TextStyle(
                                            fontFamily: 'Pretendard Variable',
                                            fontSize: 18,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? const Color(0xFF2D3436)
                                                : const Color(0xFF737B82),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: Color(0xFFB1B3B9),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                24,
                                16,
                              ),
                              itemCount: districts.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final district = districts[index];
                                final isSelected = tempDistrict == district;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() => tempDistrict = district);
                                    setState(() {
                                      _selectedRegion = tempRegion;
                                      _selectedDistrict = district;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Text(
                                    district,
                                    style: TextStyle(
                                      fontFamily: 'Pretendard Variable',
                                      fontSize: 18,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? Colors.black
                                          : const Color(0xFF737B82),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/volunteer/1365.png',
                    height: 28,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '봉사 리스트',
                    style: TextStyle(
                      fontFamily: 'OwnglyphUiyeon',
                      fontSize: 22,
                      color: Color(0xFF1F2D3D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListSearchField(
                onChanged: (value) {
                  setState(() => _searchKeyword = value);
                },
              ),
              const SizedBox(height: 12),
              ListFilterChips(
                filters: listFilters,
                selected: _selectedFilter,
                locationLabel: _locationFilterLabel,
                onTapLocation: _openLocationFilterSheet,
                onSelected: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListResultsView(
                  items: _visibleItems,
                  onTapItem: (item) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListDetailScreen(item: item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
