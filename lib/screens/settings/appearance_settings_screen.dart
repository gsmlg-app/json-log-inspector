import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:json_log_inspector/screens/settings/settings_screen.dart';
import 'package:json_log_inspector/screens/settings/widgets/settings_page_shell.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  static const name = 'Appearance Settings';
  static const path = 'appearance';

  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<DmThemeBloc>();

    return DmSettingsPageShell(
      selectedKey: const Key(SettingsScreen.name),
      title: context.l10n.appearance,
      subtitle: 'Choose how the interface responds to light and dark modes.',
      hero: BlocBuilder<DmThemeBloc, DmThemeState>(
        bloc: themeBloc,
        builder: (context, state) {
          return DmSettingsHeroCard(
            icon: Icons.brightness_6_outlined,
            title: 'Theme Mode',
            description:
                'Switch between light, dark, or system-following behavior with live previews.',
            footer: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DmSettingsMetaPill(
                  icon: state.themeMode.iconOutlined is Icon
                      ? (state.themeMode.iconOutlined as Icon).icon ??
                            Icons.brightness_auto_outlined
                      : Icons.brightness_auto_outlined,
                  label: state.themeMode.title,
                ),
              ],
            ),
          );
        },
      ),
      child: BlocBuilder<DmThemeBloc, DmThemeState>(
        bloc: themeBloc,
        builder: (context, state) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: Text(context.l10n.appearance),
                tiles: <AbstractSettingsTile>[
                  CustomSettingsTile(
                    child: _AppearancePicker(
                      currentMode: state.themeMode,
                      onModeChanged: (mode) {
                        themeBloc.add(DmSetThemeMode(mode));
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppearancePicker extends StatelessWidget {
  const _AppearancePicker({
    required this.currentMode,
    required this.onModeChanged,
  });

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final children = [
          _AppearanceOption(
            label: context.l10n.lightTheme,
            isSelected: currentMode == ThemeMode.light,
            onTap: () => onModeChanged(ThemeMode.light),
            preview: _ModePreview(
              left: _MiniWindow(brightness: Brightness.light),
            ),
          ),
          _AppearanceOption(
            label: context.l10n.darkTheme,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => onModeChanged(ThemeMode.dark),
            preview: _ModePreview(
              left: _MiniWindow(brightness: Brightness.dark),
            ),
          ),
          _AppearanceOption(
            label: context.l10n.systemTheme,
            isSelected: currentMode == ThemeMode.system,
            onTap: () => onModeChanged(ThemeMode.system),
            preview: _ModePreview(
              left: _MiniWindow(brightness: Brightness.light),
              right: _MiniWindow(brightness: Brightness.dark),
            ),
          ),
        ];

        if (compact) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.preview,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
        : theme.colorScheme.surface;
    final border = Border.all(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.38)
          : theme.colorScheme.outlineVariant,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: border,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label, style: theme.textTheme.titleSmall),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 12),
              preview,
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePreview extends StatelessWidget {
  const _ModePreview({required this.left, this.right});

  final Widget left;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    if (right == null) {
      return left;
    }

    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right!),
      ],
    );
  }
}

class _MiniWindow extends StatelessWidget {
  const _MiniWindow({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isLight = brightness == Brightness.light;
    final background = isLight
        ? const Color(0xFFFBFBFC)
        : const Color(0xFF121821);
    final topBar = isLight ? const Color(0xFFF1F3F6) : const Color(0xFF1F2937);
    final rail = isLight ? const Color(0xFFE8EDF4) : const Color(0xFF17202B);
    final surface = isLight ? Colors.white : const Color(0xFF0F1720);
    final accent = isLight ? const Color(0xFF2563EB) : const Color(0xFF60A5FA);

    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: topBar,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 24,
                    decoration: BoxDecoration(
                      color: rail,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFC9D3E0)
                                : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isLight
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFF253041),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 42,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isLight
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFF253041),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
