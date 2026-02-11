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

  List<ListItem> get _visibleItems {
    final String keyword = _searchKeyword.trim().toLowerCase();

    final filteredByKeyword = mockListItems.where((item) {
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
