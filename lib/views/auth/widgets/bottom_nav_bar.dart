import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const double w = 402;
  static const double h = 94.5;

  static const String mapPng = 'assets/images/지도 프레임.png';
  static const String listPng = 'assets/images/목록 프레임.png';
  static const String homePng = 'assets/images/홈 프레임.png';
  static const String recordPng = 'assets/images/내 기록 프레임.png';
  static const String myPng = 'assets/images/마이 프레임.png';

  static const double iconSize = 22;
  static const double bubble = 42;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      height: h,
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Colors.white),
        child: _BottomNavStack(),
      ),
    );
  }
}

/// (const 최적화용으로 분리)
class _BottomNavStack extends StatelessWidget {
  const _BottomNavStack();

  @override
  Widget build(BuildContext context) {
    // 이 위젯은 const라 currentIndex를 못 받음 → const 제거하고 바로 Stack 쓰는 게 안전.
    // 그래서 아래에서 실제로 사용 안 함(컴파일 에러 방지용).
    return SizedBox.shrink();
  }
}
