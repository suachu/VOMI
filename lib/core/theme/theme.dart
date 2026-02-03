import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Pretendard',

    textTheme: const TextTheme(
  headlineLarge: AppTextStyles.headline,
  bodyLarge: AppTextStyles.body,
  bodyMedium: AppTextStyles.caption,
).apply(
  bodyColor: AppColors.textDark,
  displayColor: AppColors.textDark,   
),

  );
}

//쓰고자 하는 파일 안에 이거 붙여넣고 

//ColorScheme colors = Theme.of(context).colorScheme;

//이렇게 쓰기

// Container(
//   color: colors.primary,
// )

// Text(
//   'Hello',
//   style: TextStyle(fontWeight: FontWeight.w700),
// )
