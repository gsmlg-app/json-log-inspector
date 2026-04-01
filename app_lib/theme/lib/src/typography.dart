import 'package:flutter/material.dart';

TextTheme buildAppTextTheme(TextTheme base) {
  final bodyTheme = base;

  TextStyle? titleStyle(
    TextStyle? style, {
    FontWeight weight = FontWeight.w700,
    double? letterSpacing,
  }) {
    if (style == null) {
      return null;
    }

    return style.copyWith(
      fontFamily: 'Trebuchet MS',
      fontFamilyFallback: const ['Avenir Next', 'Verdana', 'Segoe UI'],
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle? bodyStyle(
    TextStyle? style, {
    FontWeight? weight,
    double? letterSpacing,
  }) {
    if (style == null) {
      return null;
    }

    return style.copyWith(
      fontFamily: 'Verdana',
      fontFamilyFallback: const ['Trebuchet MS', 'Segoe UI', 'Arial'],
      fontWeight: weight ?? style.fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  return bodyTheme.copyWith(
    displayLarge: titleStyle(
      bodyTheme.displayLarge,
      weight: FontWeight.w600,
      letterSpacing: -1.2,
    ),
    displayMedium: titleStyle(
      bodyTheme.displayMedium,
      weight: FontWeight.w600,
      letterSpacing: -0.8,
    ),
    displaySmall: titleStyle(
      bodyTheme.displaySmall,
      weight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineLarge: titleStyle(bodyTheme.headlineLarge, weight: FontWeight.w600),
    headlineMedium: titleStyle(
      bodyTheme.headlineMedium,
      weight: FontWeight.w600,
    ),
    headlineSmall: titleStyle(bodyTheme.headlineSmall, weight: FontWeight.w600),
    titleLarge: titleStyle(bodyTheme.titleLarge),
    titleMedium: titleStyle(
      bodyTheme.titleMedium,
      weight: FontWeight.w700,
      letterSpacing: -0.1,
    ),
    titleSmall: titleStyle(bodyTheme.titleSmall, weight: FontWeight.w700),
    labelLarge: bodyStyle(
      bodyTheme.labelLarge,
      weight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
    labelMedium: bodyStyle(
      bodyTheme.labelMedium,
      weight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    labelSmall: bodyStyle(
      bodyTheme.labelSmall,
      weight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    bodyLarge: bodyStyle(bodyTheme.bodyLarge),
    bodyMedium: bodyStyle(bodyTheme.bodyMedium),
    bodySmall: bodyStyle(bodyTheme.bodySmall, letterSpacing: 0.1),
  );
}
