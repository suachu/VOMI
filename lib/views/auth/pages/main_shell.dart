import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/home_indicator.dart';
import '../widgets/screen_frame.dart';

/// ✅ 4) 확인 누른 뒤 나오는 화면: 네비게이션 바
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 2; // 기본 홈 선택

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenFrame(
        child: Stack(
          children: [
            // (임시 콘텐츠)
            const Positioned(
              left: 20,
              top: 120,
              child: Text(
                'MainShell (콘텐츠 자리)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            // ✅ 네비게이션 바: top=779 고정
            Positioned(
              left: 0,
              top: 779,
              child: BottomNavBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
              ),
            ),

            // ✅ 홈 인디케이터
            const Positioned(left: 128.50, top: 861, child: HomeIndicator()),
          ],
        ),
      ),
    );
  }
}
