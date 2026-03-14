# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JSON Log Inspector is a Flutter desktop/web application for viewing, filtering, and analyzing JSONL (JSON Lines) log files. Built on a modular monorepo architecture with BLoC state management.

**Requirements**: Flutter SDK >=3.8.0, Dart >=3.8.0

## App-Specific Architecture

The log inspection pipeline follows a clean data flow:

```
log_models (data) -> log_parser (I/O + indexing) -> log_viewer_bloc (state) -> log_viewer_widgets (UI)
```

### Core Packages (custom to this project)

- `app_lib/log_models/` - Data models: `LogRecord`, `FilterRule`, `FilterPreset`, `RequestData`, `ResponseData`
- `app_lib/log_parser/` - Lazy file indexing (`FileIndexer`), on-demand reading (`EntryReader` with LRU cache), filtering (`FilterEngine` with Isolate support for >1000 lines), key path discovery
- `app_bloc/log_viewer/` - Three interdependent BLoCs:
  - `LogFileBloc` - File lifecycle (open, index, clear)
  - `FilterBloc` - Filter rules, search, presets (persisted to SharedPreferences)
  - `SelectionBloc` - Selected entry + paired request/response tracking
- `app_widget/log_viewer/` - UI components: `LogListTile`, `DetailPanel`, `FilterBar`, `FilterRuleBuilder`, `BodyViewer`, `JsonTreeView`

### Main Screen

`lib/screens/log_viewer/log_viewer_screen.dart` is the primary screen with:
- Adaptive layout: desktop (>800px) shows master-detail split; mobile shows list with modal detail
- Toolbar with file picker, filter bar, filter rule builder dialog, and preset management
- Status bar showing file stats (total/valid/shown lines)
- Route: `/log-viewer` (navigated to from SplashScreen after 1s)

### Navigation Flow

`SplashScreen` (`/`) -> 1s delay -> `LogViewerScreen` (`/log-viewer`)

Navigation destinations: Log Viewer, Settings (defined in `lib/destination.dart`)

## Monorepo Structure

```
├── lib/                    # Main app entry point and screens
├── app_bloc/               # BLoC state management packages
├── app_lib/                # Core utilities and domain logic
├── app_widget/             # Reusable UI components
├── app_plugin/             # Native platform plugins (federated)
├── bricks/                 # Mason templates for code generation
├── test_bricks/            # Brick tests (one folder per brick)
└── third_party/            # Modified third-party packages
```

**Workspace packages** (defined in root `pubspec.yaml` `workspace:` section -- no separate melos.yaml):
- `app_lib/`: log_models, log_parser, database, gamepad, theme, locale, provider, logging, secure_storage
- `app_bloc/`: log_viewer, gamepad, navigation, theme, error_handler
- `app_widget/`: log_viewer, adaptive, artwork, chart, feedback, web_view
- `app_form/`: demo
- `app_plugin/`: client_info/ (federated plugin)
- `third_party/`: form_bloc, flutter_form_bloc, flutter_adaptive_scaffold, settings_ui

## Development Commands

### Setup
```bash
dart pub global activate melos
dart pub global activate mason_cli
melos bootstrap
mason get
```

### Common Workflows
```bash
melos run prepare          # Bootstrap + gen-l10n + build-runner (full setup)
melos run analyze          # Lint all packages (--fatal-warnings)
melos run format           # Format all packages
melos run format-check     # Check formatting (CI uses this)
melos run test             # Run all tests (flutter + dart)
```

### Individual Package Operations
```bash
flutter test test/screens/log_viewer/log_viewer_screen_test.dart   # Single test file
cd app_lib/log_parser && flutter test                               # Package tests
cd app_lib/theme && dart run build_runner build --delete-conflicting-outputs
```

### Code Generation with Mason
```bash
mason make screen --name ScreenName --folder subfolder
mason make widget --name WidgetName --type stateless --folder components
mason make simple_bloc -o app_bloc/feature_name --name=feature_name
mason make form_bloc --name Login --field_names "email,password"
mason make native_plugin --name plugin_name --description "Description" --package_prefix app -o app_plugin
```

See [BRICKS.md](./docs/BRICKS.md) for complete brick documentation.

## Key Entry Points

- `lib/main.dart` - App initialization: MainProvider, AppLogger, AppDatabase, SharedPreferences
- `lib/app.dart` - Root widget with ThemeBloc and MaterialApp.router
- `lib/router.dart` - GoRouter configuration (initial route: SplashScreen `/`)
- `lib/screens/log_viewer/` - Main log viewer screen
- `lib/destination.dart` - Navigation destinations for adaptive scaffold

## Architecture Patterns

### Routing Pattern
Screens define static `name` and `path` constants for GoRouter:
```dart
class LogViewerScreen extends StatelessWidget {
  static const name = 'Log Viewer';
  static const path = '/log-viewer';
}
```

### Package Dependencies
Use `<package_name>: any` for workspace packages in pubspec.yaml. Never use path dependencies.

### Theme
`ThemeBloc` manages theme state. Color schemes: fire, green, violet, wheat. Supports light/dark modes.

## Testing

Tests co-located with packages. Key test areas:
- `app_lib/log_parser/test/` - File indexing, entry reading, filter engine, LRU cache
- `app_bloc/log_viewer/test/` - Filter and selection BLoC tests
- `app_widget/log_viewer/test/` - Widget tests for all log viewer components
- `test/screens/` - Screen-level widget tests

```bash
melos run test:dart       # Non-Flutter packages only
melos run test:flutter    # Flutter packages only
```

## Development Environment

Uses Nix/Devenv for reproducible environment. Auto-loads via direnv (`.envrc`).

## Running the App

```bash
flutter run -d macos       # macOS (primary target)
flutter run -d chrome      # Web
flutter run -d linux       # Linux
```

## CI Workflows

- `ci.yml` - Format check, analyze, test, and build (skips for docs/config changes)
- `brick-test.yml` - Tests Mason bricks (only runs when brick files change)
- `release.yml` - Manual workflow for creating releases with platform builds
