import 'package:flutter/material.dart';

class BackIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const BackIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 35,
        height: 35,
        child: Center(
          child: Image.asset(
            'assets/images/b.png',
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
