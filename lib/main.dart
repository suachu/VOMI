import 'package:flutter/material.dart';
import 'package:vomi/views/character/character_select_page.dart';
import 'package:vomi/core/theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CharacterSelectPage(userName: '영준'),
    );
  }
}

