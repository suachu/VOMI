import 'package:flutter/material.dart';

import '../widgets/home_indicator.dart';
import '../widgets/rounded_action_button.dart';
import '../widgets/screen_frame.dart';
import 'login_method_page.dart';

/// 1) 첫 페이지
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _goNext(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginMethodPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenFrame(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // ✅ V 로고
            Positioned(
              left: 94.95,
              top: 245,
              child: Image.asset(
                'assets/images/V.png',
                width: 160,
                height: 179,
                fit: BoxFit.contain,
              ),
            ),

            // ✅ omi 로고
            Positioned(
              left: 170.95,
              top: 390,
              child: Image.asset(
                'assets/images/omi.png',
                width: 146,
                height: 31,
                fit: BoxFit.contain,
              ),
            ),

            // 로그인 버튼
            Positioned(
              left: 80.65,
              top: 684.45,
              child: RoundedActionButton(
                width: 240,
                height: 68.10,
                text: '로그인',
                background: const Color(0xFFACD7E6),
                textStyle: const TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.50,
                ),
                onTap: () => _goNext(context),
              ),
            ),

            // 회원가입 텍스트
            const Positioned(
              left: 178.65,
              top: 763.81,
              child: Text(
                '회원가입',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 2.08,
                ),
              ),
            ),

            // 하단 홈 인디케이터
            const Positioned(left: 128.50, top: 861, child: HomeIndicator()),
          ],
        ),
      ),
    );
  }
}
