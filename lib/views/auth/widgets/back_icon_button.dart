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
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
