import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginLandingPage(),
    );
  }
}

/// ===========================
/// 1️⃣ 랜딩 페이지 (iPhone 16 기준)
/// ===========================
class LoginLandingPage extends StatelessWidget {
  const LoginLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: SafeArea(
        child: Stack(
          children: [
            // V 이미지 (160 x 179)
            Positioned(
              top: 150,
              left: 104.95,
              child: Image.asset(
                'assets/images/V.png',
                width: 160,
                height: 179,
                fit: BoxFit.contain,
              ),
            ),

            // omi 이미지 (146 x 31)
            Positioned(
              top: 270,
              left: 230,
              child: Image.asset(
                'assets/images/omi.png',
                width: 146,
                height: 31,
                fit: BoxFit.contain,
              ),
            ),

            // 로그인 버튼 (240 x 68.1)
            Positioned(
              bottom: 42,
              left: (screenWidth - 240) / 2, // iPhone 16 = 76.5
              child: SizedBox(
                width: 240,
                height: 68.1,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginOptionsPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFACD7E6),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(34),
                    ),
                  ),
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===========================
/// 2️⃣ 로그인 옵션 페이지
/// ===========================
class LoginOptionsPage extends StatelessWidget {
  const LoginOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '가장 편한 방법으로\n시작해 보세요!',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 26),

            // 휴대폰 번호로 계속하기 (345 x 55)
            Center(
              child: LoginButton(
                label: '휴대폰 번호로 계속하기',
                background: const Color(0xFFACD7E6),
                textColor: Colors.black,
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFD3D6DA))),
                  SizedBox(width: 12),
                  Text(
                    '또는',
                    style: TextStyle(color: Color(0xFF9AA0A6)),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Divider(color: Color(0xFFD3D6DA))),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const SizedBox(height: 12),
            SocialButton(
              label: '카카오로 계속하기',
              icon: 'assets/images/K.png',
              background: Color(0xFFFEE500),
              textColor: Colors.black,
            ),

            const SizedBox(height: 12),
            SocialButton(
              label: '네이버로 계속하기',
              icon: 'assets/images/N.png',
              background: Color(0xFF03C75A),
              textColor: Colors.white,
            ),

            const SizedBox(height: 12),
            SocialButton(
              label: 'Google로 계속하기',
              icon: 'assets/images/G.png',
              background: Colors.white,
              textColor: Colors.black,
              border: true,
            ),

            const SizedBox(height: 12),
            SocialButton(
              label: 'Apple로 계속하기',
              icon: 'assets/images/A.png',
              background: Colors.black,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// ===========================
/// 공용 버튼 (345 x 55)
/// ===========================
class LoginButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 345,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// ===========================
/// 소셜 버튼 (345 x 55)
/// ===========================
class SocialButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color background;
  final Color textColor;
  final bool border;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.textColor,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 345,
        height: 55,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            backgroundColor: background,
            side: border
                ? const BorderSide(color: Color(0xFFDADCE0))
                : BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Image.asset(icon, width: 22),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
