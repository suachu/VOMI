import 'package:flutter/material.dart';

class ListFilterChips extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;
  final String locationLabel;
  final VoidCallback onTapLocation;

  const ListFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
    required this.locationLabel,
    required this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocationFilter = locationLabel != '전체';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChipButton(
              label: hasLocationFilter ? '봉사지역 · $locationLabel' : '봉사지역',
              selected: hasLocationFilter,
              onTap: onTapLocation,
            ),
          ),
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChipButton(
                label: filter,
                selected: selected == filter,
                onTap: () => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : const Color(0xFFF1F3F5),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF2D3436),
            ),
          ),
        ),
      ),
    );
  }
}
