import 'package:flutter/material.dart';
import 'package:vomi/views/bottom_nav.dart';
import 'package:vomi/views/main/calendar_screen.dart';
import 'package:vomi/views/main/feed_screen.dart';
import 'package:vomi/views/main/list_screen.dart';
import 'package:vomi/views/main/map_screen.dart';
import 'package:vomi/views/main/my_page_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 2; // default to Home

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          MapScreen(),
          ListScreen(),
          HomeScreen(),
          CalendarScreen(),
          MyPageScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}
