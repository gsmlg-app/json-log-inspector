# JSON Log Inspector

A Flutter desktop/web application for viewing, filtering, and analyzing JSONL (JSON Lines) log files. Supports large files through lazy streaming with byte-offset indexing, advanced filtering with presets, and request/response pairing.

## Features

- **JSONL Log Viewing** - Open and inspect `.jsonl`, `.json`, and `.log` files
- **Lazy Streaming** - Byte-offset indexing for memory-efficient handling of large files
- **Advanced Filtering** - Create filter rules by key path with operators (equals, contains, greaterThan, etc.)
- **Full-Text Search** - Case-insensitive search across raw JSON content
- **Filter Presets** - Save and apply reusable filter configurations (includes defaults: "Errors only", "Slow requests", "SSE streams")
- **Request/Response Pairing** - Automatically pairs related entries by request ID
- **Adaptive Layout** - Desktop master-detail view (>800px) or mobile list with modal detail
- **JSON Tree View** - Hierarchical expandable view of JSON data
- **Theme Support** - Multiple color schemes (fire, green, violet, wheat) with light/dark modes

## Getting Started

### Prerequisites

- Flutter SDK >=3.8.0
- Dart SDK >=3.8.0
- Git LFS (for image assets)

### Installation

```bash
git clone https://github.com/gsmlg-app/json-log-inspector.git
cd json-log-inspector
git lfs install && git lfs pull

dart pub global activate melos
dart pub global activate mason_cli
melos bootstrap
mason get
```

### Running

```bash
flutter run -d macos       # macOS (primary target)
flutter run -d chrome      # Web
flutter run -d linux       # Linux
```

## Architecture

Modular monorepo with clean architecture, managed by Melos. The log inspection pipeline:

```
log_models (data) -> log_parser (I/O + indexing) -> log_viewer_bloc (state) -> log_viewer_widgets (UI)
```

### Core Packages

| Package | Location | Purpose |
|---------|----------|---------|
| log_models | `app_lib/log_models/` | Data models (`LogRecord`, `FilterRule`, `FilterPreset`) |
| log_parser | `app_lib/log_parser/` | File indexing, entry reading with LRU cache, filter engine |
| log_viewer_bloc | `app_bloc/log_viewer/` | BLoC state management (file, filter, selection) |
| log_viewer_widgets | `app_widget/log_viewer/` | UI components (list tile, detail panel, filter bar, JSON tree) |

### Monorepo Structure

- **`lib/`** - Main app entry point, screens, and routing
- **`app_lib/`** - Core libraries (log_models, log_parser, database, theme, locale, logging)
- **`app_bloc/`** - BLoC packages (log_viewer, theme, navigation, gamepad)
- **`app_widget/`** - UI components (log_viewer, adaptive, artwork, feedback)
- **`app_plugin/`** - Native platform plugins (federated architecture)
- **`bricks/`** - Mason templates for code generation
- **`third_party/`** - Modified third-party packages

## Development

```bash
melos run prepare          # Full setup: bootstrap + gen-l10n + build-runner
melos run analyze          # Lint all packages
melos run format           # Format all packages
melos run test             # Run all tests
```

See [CLAUDE.md](./CLAUDE.md) for detailed development guidance and [docs/INDEX.md](./docs/INDEX.md) for full documentation.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
