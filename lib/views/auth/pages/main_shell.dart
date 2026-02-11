import 'package:flutter/material.dart';
import 'package:vomi/views/main/main_shell.dart' as app_main;

/// 인증 플로우에서 진입하더라도 메인 셸을 재사용해
/// 하단 네비게이션(리스트 탭 포함) 동작을 동일하게 유지한다.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const app_main.MainShell();
  }
}
