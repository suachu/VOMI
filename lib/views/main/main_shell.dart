import 'package:flutter/material.dart';
import 'package:vomi/volunteer/screens/volunteer_list_screen.dart';
import 'package:vomi/views/bottom_nav.dart';
import 'package:vomi/views/main/calendar_screen.dart';
import 'package:vomi/views/main/feed_screen.dart';
import 'package:vomi/views/main/map_screen.dart';
import 'package:vomi/views/main/my_page_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const String _volunteerServiceKey =
      '55c97393c0b45a46ae1a742f4bee2153a92fb6db8782f53d51792cd053911195';
  int _index = 2; // default to Home

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          MapScreen(),
          VolunteerListScreen(serviceKey: _volunteerServiceKey),
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
