import 'package:flutter/material.dart';
import 'package:vomi/views/main/list/widgets/list_item_card.dart';
import 'package:vomi/views/main/list_models.dart';

class ListResultsView extends StatelessWidget {
  final List<ListItem> items;
  final ValueChanged<ListItem> onTapItem;

  const ListResultsView({
    super.key,
    required this.items,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('조건에 맞는 봉사 리스트가 없어요.'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListItemCard(item: item, onTap: () => onTapItem(item));
      },
    );
  }
}
