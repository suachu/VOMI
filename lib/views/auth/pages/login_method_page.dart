import 'package:flutter/material.dart';
import 'package:vomi/services/auth_service.dart';
import 'package:vomi/views/main/main_shell.dart';

import '../widgets/back_icon_button.dart';
import '../widgets/home_indicator.dart';
import '../widgets/rounded_action_button.dart';
import '../widgets/screen_frame.dart';
import 'phone_join_page.dart';

/// 2) 로그인 방법 선택 페이지
class LoginMethodPage extends StatefulWidget {
  const LoginMethodPage({super.key});

  @override
  State<LoginMethodPage> createState() => _LoginMethodPageState();
}

class _LoginMethodPageState extends State<LoginMethodPage> {
  bool _phonePressedFlash = false;
  bool _isGoogleLoading = false;

  void _goPhoneJoin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneJoinPage()),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      await AuthService().signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인에 실패했어요: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Widget _orLine() {
    return Container(
      width: 149.21,
      height: 1,
      color: const Color(0xFF898A8D),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenFrame(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 타이틀
            const Positioned(
              left: 41,
              top: 146.11,
              child: Text(
                '가장 편한 방법으로',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.20,
                  letterSpacing: -1,
                ),
              ),
            ),
            const Positioned(
              left: 41,
              top: 182.11,
              child: Text(
                '시작해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.29,
                  letterSpacing: -1,
                ),
              ),
            ),

            // 뒤로가기
            Positioned(
              left: 23.70,
              top: 86,
              child: BackIconButton(onTap: () => Navigator.pop(context)),
            ),

            // 휴대폰 버튼
            Positioned(
              left: 27.82,
              top: 269.95,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => setState(() => _phonePressedFlash = true),
                onTapCancel: () => setState(() => _phonePressedFlash = false),
                onTapUp: (_) {
                  setState(() => _phonePressedFlash = false);
                  _goPhoneJoin(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  width: 345,
                  height: 55,
                  decoration: ShapeDecoration(
                    color: _phonePressedFlash
                        ? Colors.white
                        : const Color(0xFFACD7E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '휴대폰 번호로 계속하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2F2F2F),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 2.12,
                    ),
                  ),
                ),
              ),
            ),

            // 또는
            Positioned(left: 28.81, top: 376.79, child: _orLine()),
            Positioned(left: 223.16, top: 376.79, child: _orLine()),
            const Positioned(
              left: 188.82,
              top: 357.18,
              child: Text(
                '또는',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB1B3B9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 2.77,
                ),
              ),
            ),

            // 카카오
            Positioned(
              left: 23.70,
              top: 469.69,
              child: RoundedActionButton(
                width: 345,
                height: 55,
                text: '카카오로 계속하기',
                background: const Color(0xFFFDE500),
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 2.12,
                ),
                radius: 10,
                onTap: () {},
              ),
            ),
            Positioned(
              left: 38.17,
              top: 487.38,
              child: Image.asset(
                'assets/images/K.png',
                width: 34.48,
                height: 19.62,
                fit: BoxFit.contain,
              ),
            ),

            // 네이버
            Positioned(
              left: 23.70,
              top: 533.16,
              child: RoundedActionButton(
                width: 345,
                height: 55,
                text: '네이버로 계속하기',
                background: const Color(0xFF00BF18),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 2.12,
                ),
                radius: 10,
                onTap: () {},
              ),
            ),
            Positioned(
              left: 41.71,
              top: 547.49,
              child: Image.asset(
                'assets/images/N.png',
                width: 26.34,
                height: 26.34,
                fit: BoxFit.contain,
              ),
            ),

            // Google
            Positioned(
              left: 23.70,
              top: 596.63,
              child: RoundedActionButton(
                width: 345,
                height: 55,
                text: 'Google로 계속하기',
                background: Colors.white,
                border: const BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 2.12,
                ),
                radius: 10,
                onTap: _isGoogleLoading
                    ? null
                    : _signInWithGoogle,
              ),
            ),
            Positioned(
              left: 46.1,
              top: 616.29,
              child: Image.asset(
                'assets/images/G.png',
                width: 17.55,
                height: 17.91,
                fit: BoxFit.contain,
              ),
            ),

            // Apple
            Positioned(
              left: 23.70,
              top: 660.09,
              child: RoundedActionButton(
                width: 345,
                height: 55,
                text: 'Apple로 계속하기',
                background: Colors.black,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 2.12,
                ),
                radius: 10,
                onTap: () {},
              ),
            ),
            Positioned(
              left: 46.88,
              top: 678.09,
              child: Image.asset(
                'assets/images/A.png',
                width: 16,
                height: 19,
                fit: BoxFit.contain,
              ),
            ),

            // 홈 인디케이터
            const Positioned(left: 128.50, top: 861, child: HomeIndicator()),
          ],
        ),
      ),
    );
  }
}
