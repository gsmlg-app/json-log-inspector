import 'package:flutter/material.dart';
import 'package:settings_ui/src/sections/abstract_settings_section.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Material Design 3 settings section implementation.
///
/// Follows M3 List specifications:
/// - Section header: 14sp labelLarge, primary color
/// - Header padding: 16dp horizontal, 16dp top, 8dp bottom
/// - No visual container around tiles (flat style)
/// - Optional dividers between tiles (handled by theme)
///
/// See: https://m3.material.io/components/lists/specs
class MaterialSettingsSection extends AbstractSettingsSection {
  const MaterialSettingsSection({
    required super.tiles,
    super.margin,
    super.title,
    super.key,
  });

  static const double _cornerRadius = 24.0;
  static const double _headerFontSize = 14.0;
  static const double _horizontalPadding = 16.0;
  static const double _headerTopPadding = 16.0;
  static const double _headerBottomPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return buildSectionBody(context);
  }

  Widget buildSectionBody(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.of(context).textScaler;
    final tileList = buildTileList();

    final tileSurface = Container(
      decoration: BoxDecoration(
        color:
            theme.themeData.settingsSectionBackground ??
            colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(
          color: theme.themeData.dividerColor ?? colorScheme.outlineVariant,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: tileList,
      ),
    );

    if (title == null) {
      return Padding(padding: margin ?? EdgeInsets.zero, child: tileSurface);
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (M3 labelLarge style)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: textScaler.scale(_headerTopPadding),
              bottom: textScaler.scale(_headerBottomPadding),
              start: _horizontalPadding,
              end: _horizontalPadding,
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color:
                    theme.themeData.titleTextColor ??
                    colorScheme.onSurfaceVariant,
                fontSize: _headerFontSize,
                fontWeight: FontWeight.w600,
              ),
              child: title!,
            ),
          ),
          tileSurface,
        ],
      ),
    );
  }

  Widget buildTileList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: tiles.length,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return tiles[index];
      },
    );
  }
}
