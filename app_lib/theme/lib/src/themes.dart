import 'package:app_theme/src/extension.dart';
import 'package:app_theme/src/typography.dart';
import 'package:flutter/material.dart';

final themeList = <AppTheme>[
  DuskmoonTheme.orbit(),
  DuskmoonTheme.solar(),
  DuskmoonTheme.tide(),
  DuskmoonTheme.aurora(),
];

final _panelRadius = BorderRadius.circular(20);
const _buttonRadius = BorderRadius.all(Radius.circular(16));
const _fieldRadius = BorderRadius.all(Radius.circular(18));

Color _hsl(double hue, double saturation, double lightness) {
  return HSLColor.fromAHSL(1, hue, saturation / 100, lightness / 100).toColor();
}

AppStatusColors _statusColorsFor(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return AppStatusColors(
      info: _hsl(199, 89, 58),
      onInfo: _hsl(240, 10, 4),
      infoContainer: _hsl(199, 89, 20),
      onInfoContainer: _hsl(199, 89, 90),
      success: _hsl(142, 71, 55),
      onSuccess: _hsl(240, 10, 4),
      successContainer: _hsl(142, 71, 20),
      onSuccessContainer: _hsl(142, 71, 90),
      warning: _hsl(38, 92, 60),
      onWarning: _hsl(240, 10, 4),
      warningContainer: _hsl(38, 92, 20),
      onWarningContainer: _hsl(38, 92, 90),
      error: _hsl(0, 84, 70),
      onError: Colors.white,
      errorContainer: _hsl(0, 84, 20),
      onErrorContainer: _hsl(0, 84, 90),
    );
  }

  return AppStatusColors(
    info: _hsl(199, 89, 48),
    onInfo: Colors.white,
    infoContainer: _hsl(199, 89, 95),
    onInfoContainer: _hsl(199, 89, 20),
    success: _hsl(142, 71, 45),
    onSuccess: Colors.white,
    successContainer: _hsl(142, 71, 95),
    onSuccessContainer: _hsl(142, 71, 18),
    warning: _hsl(38, 92, 50),
    onWarning: _hsl(38, 95, 10),
    warningContainer: _hsl(38, 92, 95),
    onWarningContainer: _hsl(38, 95, 20),
    error: _hsl(0, 84, 60),
    onError: Colors.white,
    errorContainer: _hsl(0, 84, 95),
    onErrorContainer: _hsl(0, 84, 20),
  );
}

ThemeData _buildThemeData(
  ColorScheme colorScheme,
  AppStatusColors statusColors,
) {
  final textTheme = buildAppTextTheme(
    ThemeData(
      brightness: colorScheme.brightness,
      useMaterial3: true,
    ).textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );

  final baseBorder = OutlineInputBorder(
    borderRadius: _fieldRadius,
    borderSide: BorderSide(color: colorScheme.outlineVariant),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    textTheme: textTheme,
    dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.75),
    extensions: <ThemeExtension<dynamic>>[statusColors],
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      toolbarTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      groupAlignment: -0.9,
      useIndicator: true,
      minWidth: 88,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.primaryContainer,
      tileHeight: 54,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
      border: baseBorder,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      deleteIconColor: colorScheme.onSurfaceVariant,
      disabledColor: colorScheme.surfaceContainerLow,
      secondarySelectedColor: colorScheme.primaryContainer,
      side: BorderSide(color: colorScheme.outlineVariant),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onPrimaryContainer,
      ),
      brightness: colorScheme.brightness,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.72),
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      elevation: 0,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: _panelRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outlineVariant),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: _buttonRadius),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerLow;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimaryContainer;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),
    ),
  );
}

ColorScheme _buildColorScheme(Brightness brightness, _AccentSet accent) {
  final isDark = brightness == Brightness.dark;

  final Color surface = isDark ? _hsl(220, 20, 10) : _hsl(0, 0, 100);
  final Color surfaceDim = isDark ? _hsl(220, 20, 8) : _hsl(40, 20, 94);
  final Color surfaceBright = isDark ? _hsl(220, 15, 18) : _hsl(0, 0, 100);
  final Color surfaceLowest = isDark ? _hsl(220, 20, 6) : _hsl(0, 0, 100);
  final Color surfaceLow = isDark ? _hsl(220, 18, 10) : _hsl(40, 30, 98);
  final Color surfaceContainer = isDark ? _hsl(220, 16, 12) : _hsl(40, 25, 96);
  final Color surfaceHigh = isDark ? _hsl(220, 14, 15) : _hsl(40, 20, 94);
  final Color surfaceHighest = isDark ? _hsl(220, 12, 18) : _hsl(40, 15, 92);
  final Color onSurface = isDark ? _hsl(220, 15, 92) : _hsl(220, 15, 15);
  final Color onSurfaceVariant = isDark ? _hsl(220, 10, 70) : _hsl(220, 10, 40);
  final Color outline = isDark ? _hsl(220, 10, 35) : _hsl(220, 10, 70);
  final Color outlineVariant = isDark ? _hsl(220, 8, 25) : _hsl(220, 8, 82);
  final Color inverseSurface = isDark ? _hsl(220, 5, 92) : _hsl(220, 20, 12);
  final Color onInverseSurface = isDark ? _hsl(220, 20, 10) : _hsl(0, 0, 100);

  return ColorScheme.fromSeed(
    seedColor: accent.primary,
    brightness: brightness,
    primary: accent.primary,
    onPrimary: accent.onPrimary,
    primaryContainer: accent.primaryContainer,
    onPrimaryContainer: accent.onPrimaryContainer,
    secondary: accent.secondary,
    onSecondary: accent.onSecondary,
    secondaryContainer: accent.secondaryContainer,
    onSecondaryContainer: accent.onSecondaryContainer,
    tertiary: accent.tertiary,
    onTertiary: accent.onTertiary,
    tertiaryContainer: accent.tertiaryContainer,
    onTertiaryContainer: accent.onTertiaryContainer,
    error: _statusColorsFor(brightness).error,
    onError: _statusColorsFor(brightness).onError,
    errorContainer: _statusColorsFor(brightness).errorContainer,
    onErrorContainer: _statusColorsFor(brightness).onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceContainerLowest: surfaceLowest,
    surfaceContainerLow: surfaceLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHighest,
    inverseSurface: inverseSurface,
    onInverseSurface: onInverseSurface,
    inversePrimary: accent.primaryContainer,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: accent.primary,
  );
}

abstract class AppTheme {
  const AppTheme({
    required this.name,
    required this.lightTheme,
    required this.darkTheme,
  });

  final String name;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  @override
  String toString() {
    return name;
  }
}

class DuskmoonTheme extends AppTheme {
  factory DuskmoonTheme.orbit() {
    return DuskmoonTheme._(_orbitPalette);
  }

  factory DuskmoonTheme.solar() {
    return DuskmoonTheme._(_solarPalette);
  }

  factory DuskmoonTheme.tide() {
    return DuskmoonTheme._(_tidePalette);
  }

  factory DuskmoonTheme.aurora() {
    return DuskmoonTheme._(_auroraPalette);
  }

  DuskmoonTheme._(_ThemePalette palette)
    : super(
        name: palette.name,
        lightTheme: _buildThemeData(
          _buildColorScheme(Brightness.light, palette.light),
          _statusColorsFor(Brightness.light),
        ),
        darkTheme: _buildThemeData(
          _buildColorScheme(Brightness.dark, palette.dark),
          _statusColorsFor(Brightness.dark),
        ),
      );
}

class DynamicTheme extends AppTheme {
  factory DynamicTheme.fromSeed(Color seedColor) {
    final light = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final dark = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return DynamicTheme._(
      _buildThemeData(light, AppStatusColors.fallback(light)),
      _buildThemeData(dark, AppStatusColors.fallback(dark)),
    );
  }

  DynamicTheme._(ThemeData lightTheme, ThemeData darkTheme)
    : super(name: 'Dynamic', lightTheme: lightTheme, darkTheme: darkTheme);
}

class _ThemePalette {
  const _ThemePalette({
    required this.name,
    required this.light,
    required this.dark,
  });

  final String name;
  final _AccentSet light;
  final _AccentSet dark;
}

class _AccentSet {
  const _AccentSet({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
}

final _orbitPalette = _ThemePalette(
  name: 'Orbit',
  light: _AccentSet(
    primary: _hsl(221, 83, 53),
    onPrimary: Colors.white,
    primaryContainer: _hsl(221, 83, 95),
    onPrimaryContainer: _hsl(221, 83, 20),
    secondary: _hsl(271, 76, 53),
    onSecondary: Colors.white,
    secondaryContainer: _hsl(271, 76, 95),
    onSecondaryContainer: _hsl(271, 76, 20),
    tertiary: _hsl(342, 92, 56),
    onTertiary: Colors.white,
    tertiaryContainer: _hsl(342, 92, 95),
    onTertiaryContainer: _hsl(342, 92, 20),
  ),
  dark: _AccentSet(
    primary: _hsl(221, 83, 63),
    onPrimary: _hsl(240, 10, 4),
    primaryContainer: _hsl(221, 83, 20),
    onPrimaryContainer: _hsl(221, 83, 90),
    secondary: _hsl(271, 76, 63),
    onSecondary: _hsl(240, 10, 4),
    secondaryContainer: _hsl(271, 76, 20),
    onSecondaryContainer: _hsl(271, 76, 90),
    tertiary: _hsl(342, 92, 66),
    onTertiary: _hsl(240, 10, 4),
    tertiaryContainer: _hsl(342, 92, 20),
    onTertiaryContainer: _hsl(342, 92, 90),
  ),
);

final _solarPalette = _ThemePalette(
  name: 'Solar',
  light: _AccentSet(
    primary: _hsl(30, 90, 55),
    onPrimary: Colors.white,
    primaryContainer: _hsl(30, 80, 92),
    onPrimaryContainer: _hsl(30, 90, 20),
    secondary: _hsl(340, 80, 60),
    onSecondary: Colors.white,
    secondaryContainer: _hsl(340, 70, 92),
    onSecondaryContainer: _hsl(340, 80, 25),
    tertiary: _hsl(270, 70, 60),
    onTertiary: Colors.white,
    tertiaryContainer: _hsl(270, 60, 92),
    onTertiaryContainer: _hsl(270, 70, 25),
  ),
  dark: _AccentSet(
    primary: _hsl(30, 90, 65),
    onPrimary: _hsl(220, 20, 10),
    primaryContainer: _hsl(30, 70, 24),
    onPrimaryContainer: _hsl(30, 90, 88),
    secondary: _hsl(340, 80, 70),
    onSecondary: _hsl(220, 20, 10),
    secondaryContainer: _hsl(340, 60, 24),
    onSecondaryContainer: _hsl(340, 80, 90),
    tertiary: _hsl(270, 70, 72),
    onTertiary: _hsl(220, 20, 10),
    tertiaryContainer: _hsl(270, 55, 24),
    onTertiaryContainer: _hsl(270, 70, 90),
  ),
);

final _tidePalette = _ThemePalette(
  name: 'Tide',
  light: _AccentSet(
    primary: _hsl(200, 84, 48),
    onPrimary: Colors.white,
    primaryContainer: _hsl(200, 84, 94),
    onPrimaryContainer: _hsl(200, 84, 18),
    secondary: _hsl(175, 62, 42),
    onSecondary: Colors.white,
    secondaryContainer: _hsl(175, 60, 92),
    onSecondaryContainer: _hsl(175, 62, 18),
    tertiary: _hsl(245, 80, 62),
    onTertiary: Colors.white,
    tertiaryContainer: _hsl(245, 80, 95),
    onTertiaryContainer: _hsl(245, 80, 20),
  ),
  dark: _AccentSet(
    primary: _hsl(200, 84, 62),
    onPrimary: _hsl(220, 20, 10),
    primaryContainer: _hsl(200, 70, 22),
    onPrimaryContainer: _hsl(200, 84, 88),
    secondary: _hsl(175, 62, 58),
    onSecondary: _hsl(220, 20, 10),
    secondaryContainer: _hsl(175, 46, 22),
    onSecondaryContainer: _hsl(175, 62, 86),
    tertiary: _hsl(245, 80, 74),
    onTertiary: _hsl(220, 20, 10),
    tertiaryContainer: _hsl(245, 55, 24),
    onTertiaryContainer: _hsl(245, 80, 90),
  ),
);

final _auroraPalette = _ThemePalette(
  name: 'Aurora',
  light: _AccentSet(
    primary: _hsl(145, 65, 42),
    onPrimary: Colors.white,
    primaryContainer: _hsl(145, 55, 90),
    onPrimaryContainer: _hsl(145, 65, 15),
    secondary: _hsl(199, 89, 48),
    onSecondary: Colors.white,
    secondaryContainer: _hsl(199, 89, 95),
    onSecondaryContainer: _hsl(199, 89, 20),
    tertiary: _hsl(280, 60, 58),
    onTertiary: Colors.white,
    tertiaryContainer: _hsl(280, 60, 94),
    onTertiaryContainer: _hsl(280, 60, 20),
  ),
  dark: _AccentSet(
    primary: _hsl(145, 60, 52),
    onPrimary: _hsl(220, 20, 10),
    primaryContainer: _hsl(145, 40, 18),
    onPrimaryContainer: _hsl(145, 55, 80),
    secondary: _hsl(199, 89, 58),
    onSecondary: _hsl(220, 20, 10),
    secondaryContainer: _hsl(199, 50, 20),
    onSecondaryContainer: _hsl(199, 89, 85),
    tertiary: _hsl(280, 60, 70),
    onTertiary: _hsl(220, 20, 10),
    tertiaryContainer: _hsl(280, 40, 25),
    onTertiaryContainer: _hsl(280, 60, 85),
  ),
);
