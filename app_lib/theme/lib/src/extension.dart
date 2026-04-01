import 'package:flutter/material.dart';

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
  });

  factory AppStatusColors.fallback(ColorScheme colorScheme) {
    return AppStatusColors(
      info: colorScheme.primary,
      onInfo: colorScheme.onPrimary,
      infoContainer: colorScheme.primaryContainer,
      onInfoContainer: colorScheme.onPrimaryContainer,
      success: const Color(0xFF2E7D32),
      onSuccess: Colors.white,
      successContainer: const Color(0xFFD9F2D9),
      onSuccessContainer: const Color(0xFF0F3911),
      warning: const Color(0xFFE58E00),
      onWarning: const Color(0xFF251300),
      warningContainer: const Color(0xFFFFE8BF),
      onWarningContainer: const Color(0xFF5B3900),
      error: colorScheme.error,
      onError: colorScheme.onError,
      errorContainer: colorScheme.errorContainer,
      onErrorContainer: colorScheme.onErrorContainer,
    );
  }

  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;

  @override
  AppStatusColors copyWith({
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
  }) {
    return AppStatusColors(
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
    );
  }

  @override
  AppStatusColors lerp(
    covariant ThemeExtension<AppStatusColors>? other,
    double t,
  ) {
    if (other is! AppStatusColors) {
      return this;
    }

    return AppStatusColors(
      info: Color.lerp(info, other.info, t) ?? info,
      onInfo: Color.lerp(onInfo, other.onInfo, t) ?? onInfo,
      infoContainer:
          Color.lerp(infoContainer, other.infoContainer, t) ?? infoContainer,
      onInfoContainer:
          Color.lerp(onInfoContainer, other.onInfoContainer, t) ??
          onInfoContainer,
      success: Color.lerp(success, other.success, t) ?? success,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? onSuccess,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          successContainer,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t) ??
          onSuccessContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      onWarning: Color.lerp(onWarning, other.onWarning, t) ?? onWarning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t) ??
          onWarningContainer,
      error: Color.lerp(error, other.error, t) ?? error,
      onError: Color.lerp(onError, other.onError, t) ?? onError,
      errorContainer:
          Color.lerp(errorContainer, other.errorContainer, t) ?? errorContainer,
      onErrorContainer:
          Color.lerp(onErrorContainer, other.onErrorContainer, t) ??
          onErrorContainer,
    );
  }
}

extension ThemeModeExtension on ThemeMode {
  static ThemeMode fromString(String? name) {
    switch (name) {
      case 'system':
      case 'ThemeMode.system':
        return ThemeMode.system;
      case 'light':
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'dark':
      case 'ThemeMode.dark':
        return ThemeMode.dark;
    }
    return ThemeMode.system;
  }

  String get title {
    switch (this) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Widget get icon {
    switch (this) {
      case ThemeMode.system:
        return const Icon(Icons.brightness_auto);
      case ThemeMode.light:
        return const Icon(Icons.light_mode);
      case ThemeMode.dark:
        return const Icon(Icons.dark_mode);
    }
  }

  Widget get iconOutlined {
    switch (this) {
      case ThemeMode.system:
        return const Icon(Icons.brightness_auto_outlined);
      case ThemeMode.light:
        return const Icon(Icons.light_mode_outlined);
      case ThemeMode.dark:
        return const Icon(Icons.dark_mode_outlined);
    }
  }
}

extension AppThemeDataExtension on ThemeData {
  AppStatusColors get statusColors =>
      extension<AppStatusColors>() ?? AppStatusColors.fallback(colorScheme);

  TextStyle codeTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Menlo',
      fontFamilyFallback: const ['Cascadia Code', 'Consolas', 'Courier New'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? colorScheme.onSurface,
      height: height,
    );
  }
}
