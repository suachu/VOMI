import 'package:flutter/material.dart';
import 'selectionPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  home: SelectionPage(
    userName: '영준',
  ),
);
  }
}

