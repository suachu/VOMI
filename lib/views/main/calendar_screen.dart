import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Calendar + past posts placeholder',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
