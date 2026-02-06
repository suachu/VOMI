import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NavDemoPage(),
    );
  }
}

class NavDemoPage extends StatefulWidget {
  const NavDemoPage({super.key});

  @override
  State<NavDemoPage> createState() => _NavDemoPageState();
}

class _NavDemoPageState extends State<NavDemoPage> {
  int? selectedIndex; // ✅ 처음엔 off만

  // ✅ 네비게이션 바
  static const double navW = 402;
  static const double navH = 94.5;
  static const double navLeft = 20;
  static const double navBottom = 0;

  // ✅ 아이콘 터치(슬롯) 영역: 66 x 70
  static const double iconSlotW = 66;
  static const double iconSlotH = 70;

  // ✅ 파란 원
  static const double bubble = 53;
  static const Color bubbleColor = Color(0xFFBFE6FF);

  // ✅ 눌리면 같이 위로 올라가는 정도
  static const double lift = 6;

  // ✅ 순서: 맵 → 목록 → 홈 → 기록 → 프로필
  // ✅ left/top은 "아이콘" 기준 좌표로 그대로 두고,
  //    터치영역(66x70) 안에서 아이콘을 중앙 정렬해서 표시
  final List<_NavIconSpec> specs = const [
    _NavIconSpec(
      offPath: 'assets/images/map_off.png',
      onPath: 'assets/images/map_on.png',
      left: 39,
      top: 26.5,
      w: 20,
      h: 20,
    ),
    _NavIconSpec(
      offPath: 'assets/images/list_off.png',
      onPath: 'assets/images/list_on.png',
      left: 112.34,
      top: 24.22,
      w: 20,
      h: 15.56,
    ),
    _NavIconSpec(
      offPath: 'assets/images/home_off.png',
      onPath: 'assets/images/home_on.png',
      left: 187,
      top: 22.5,
      w: 28,
      h: 28,
    ),
    _NavIconSpec(
      offPath: 'assets/images/records_off.png',
      onPath: 'assets/images/records_on.png',
      left: 268.5,
      top: 27.03,
      w: 24,
      h: 18.94,
    ),
    _NavIconSpec(
      offPath: 'assets/images/profile_off.png',
      onPath: 'assets/images/profile_on.png',
      left: 346,
      top: 27.19,
      w: 16.02,
      h: 18.78,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Stack(
        children: [
          const Positioned.fill(child: Center(child: Text("PAGE"))),

          Positioned(
            left: navLeft,
            bottom: navBottom,
            child: SafeArea(
              top: false,
              child: Container(
                width: navW,
                height: navH,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // ✅ 파란 원: 선택된 아이콘 하나만 (아이콘보다 아래)
                    if (selectedIndex != null)
                      _BubbleOnly(
                        spec: specs[selectedIndex!],
                        bubble: bubble,
                        bubbleColor: bubbleColor,
                        lift: lift,
                      ),

                    // ✅ 아이콘 5개: "66x70 터치영역" 적용
                    ...List.generate(specs.length, (i) {
                      final it = specs[i];
                      final bool selected = selectedIndex == i;

                      // ✅ 아이콘의 "중심" 좌표 (원 계산/이동에 사용)
                      final double iconCenterX = it.left + it.w / 2;
                      final double iconCenterY = it.top + it.h / 2;

                      // ✅ 66x70 터치영역을 아이콘 중심 기준으로 배치
                      final double slotLeft = iconCenterX - iconSlotW / 2;
                      final double slotTop = iconCenterY - iconSlotH / 2;

                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        left: slotLeft,
                        top: selected ? slotTop - lift : slotTop,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => selectedIndex = i),
                          child: SizedBox(
                            width: iconSlotW,
                            height: iconSlotH,
                            child: Center(
                              child: Image.asset(
                                selected ? it.onPath : it.offPath,
                                width: it.w,
                                height: it.h,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ 파란 원만 담당 (아이콘보다 아래 레이어)
class _BubbleOnly extends StatelessWidget {
  final _NavIconSpec spec;
  final double bubble;
  final Color bubbleColor;
  final double lift;

  const _BubbleOnly({
    required this.spec,
    required this.bubble,
    required this.bubbleColor,
    required this.lift,
  });

  @override
  Widget build(BuildContext context) {
    final double centerX = spec.left + spec.w / 2;
    final double centerY = spec.top + spec.h / 2;

    final double bubbleLeft = centerX - bubble / 2;
    final double bubbleTop = centerY - bubble / 2 - lift;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      left: bubbleLeft,
      top: bubbleTop,
      child: Container(
        width: bubble,
        height: bubble,
        decoration: BoxDecoration(
          color: bubbleColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _NavIconSpec {
  final String offPath;
  final String onPath;
  final double left, top, w, h;

  const _NavIconSpec({
    required this.offPath,
    required this.onPath,
    required this.left,
    required this.top,
    required this.w,
    required this.h,
  });
}
