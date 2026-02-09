import 'package:flutter/material.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'My page placeholder',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
