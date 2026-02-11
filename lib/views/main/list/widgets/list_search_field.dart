import 'package:flutter/material.dart';

class ListSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const ListSearchField({
    super.key,
    required this.onChanged,
    this.hintText = '검색',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }
}
