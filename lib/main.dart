import 'package:flutter/material.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/views/main/main_shell.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background
        ),
      home: MainShell()
    );
  }
}
