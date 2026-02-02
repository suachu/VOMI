

import 'package:flutter/material.dart';

void main() {
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

class LoginLandingPage extends StatelessWidget {
  const LoginLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: SafeArea(
        child: Stack(
          children: [
            // ===============
            // 🔵 V 이미지 (왼쪽)
            // =========================
            Positioned(
              top: 150,     // 위에서부터 거리
              left: 104.95,    // 왼쪽에서부터 거리
              child: Image.asset(
                'assets/images/V.png',
                width: 160,  // 이미지 크기
              ),
            ),

            // =========================
            // 🔵 omi 이미지 (오른쪽)
            // =========================
            Positioned(
              top: 270,     // V랑 세로 정렬 미세조정
              left: 230,    // V 옆 위치
              child: Image.asset(
                'assets/images/omi.png',
                width: 110, // 이미지 크기
              ),
            ),

            // =========================
            // 🔵 로그인 버튼 (하단)
            // =========================
            Positioned(
              bottom: 42,   // 아래에서 거리
              left: 24,
              right: 24,    // left + right → 가로 중앙 정렬
              child: SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFACD7E6),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
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

