import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  // ✅ 네비게이션 바
  static const double navW = 402;
  static const double navH = 94.5;
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
      top: 28,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double navWScaled = maxW < navW ? maxW - 24 : navW;
        final double scale = navWScaled / navW;
        final double navHScaled = navH * scale;

        return SizedBox(
          height: navHScaled,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: navBottom * scale,
              ),
              child: Container(
                width: navWScaled,
                height: navHScaled,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14 * scale,
                      offset: Offset(0, 6 * scale),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // ✅ 파란 원: 선택된 아이콘 하나만 (아이콘보다 아래)
                    if (selectedIndex >= 0)
                      _BubbleOnly(
                        spec: specs[selectedIndex],
                        bubble: bubble * scale,
                        bubbleColor: bubbleColor,
                        lift: lift * scale,
                        scale: scale,
                      ),

                    // ✅ 아이콘 5개: "66x70 터치영역" 적용
                    ...List.generate(specs.length, (i) {
                      final it = specs[i];
                      final bool selected = selectedIndex == i;

                      final double itLeft = it.left * scale;
                      final double itTop = it.top * scale;
                      final double itW = it.w * scale;
                      final double itH = it.h * scale;

                      // ✅ 아이콘의 "중심" 좌표 (원 계산/이동에 사용)
                      final double iconCenterX = itLeft + itW / 2;
                      final double iconCenterY = itTop + itH / 2;

                      // ✅ 66x70 터치영역을 아이콘 중심 기준으로 배치
                      final double slotLeft =
                          iconCenterX - (iconSlotW * scale) / 2;
                      final double slotTop =
                          iconCenterY - (iconSlotH * scale) / 2;

                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        left: slotLeft,
                        top: selected ? slotTop - (lift * scale) : slotTop,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(i),
                          child: SizedBox(
                            width: iconSlotW * scale,
                            height: iconSlotH * scale,
                            child: Center(
                              child: Image.asset(
                                selected ? it.onPath : it.offPath,
                                width: itW,
                                height: itH,
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
        );
      },
    );
  }
}

/// ✅ 파란 원만 담당 (아이콘보다 아래 레이어)
class _BubbleOnly extends StatelessWidget {
  final _NavIconSpec spec;
  final double bubble;
  final Color bubbleColor;
  final double lift;
  final double scale;

  const _BubbleOnly({
    required this.spec,
    required this.bubble,
    required this.bubbleColor,
    required this.lift,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final double centerX = (spec.left * scale) + (spec.w * scale) / 2;
    final double centerY = (spec.top * scale) + (spec.h * scale) / 2;

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
