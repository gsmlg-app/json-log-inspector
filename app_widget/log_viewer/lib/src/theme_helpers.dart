import 'package:duskmoon_theme/duskmoon_theme.dart';
import 'package:flutter/material.dart';

/// Convenience accessor for DmColorExtension semantic colors.
extension LogViewerThemeExtension on ThemeData {
  DmColorExtension? get dmColors => extension<DmColorExtension>();

  /// Status-oriented colors mapped from DmColorExtension.
  LogViewerStatusColors get statusColors => LogViewerStatusColors(this);

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

class LogViewerStatusColors {
  LogViewerStatusColors(this._theme);
  final ThemeData _theme;

  DmColorExtension? get _dm => _theme.extension<DmColorExtension>();

  Color get info => _dm?.info ?? _theme.colorScheme.primary;
  Color get success => _dm?.success ?? const Color(0xFF2E7D32);
  Color get warning => _dm?.warning ?? const Color(0xFFE58E00);
  Color get error => _theme.colorScheme.error;

  Color get infoContainer =>
      _dm?.infoContainer ?? _theme.colorScheme.primaryContainer;
  Color get onInfoContainer =>
      _dm?.onInfoContainer ?? _theme.colorScheme.onPrimaryContainer;
  Color get successContainer =>
      _dm?.successContainer ?? const Color(0xFFD9F2D9);
  Color get onSuccessContainer =>
      _dm?.onSuccessContainer ?? const Color(0xFF0F3911);
  Color get warningContainer =>
      _dm?.warningContainer ?? const Color(0xFFFFE8BF);
  Color get onWarningContainer =>
      _dm?.onWarningContainer ?? const Color(0xFF5B3900);
  Color get errorContainer => _theme.colorScheme.errorContainer;
  Color get onErrorContainer => _theme.colorScheme.onErrorContainer;

  Color get onError => _theme.colorScheme.onError;
}
