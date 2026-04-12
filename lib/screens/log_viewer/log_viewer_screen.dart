import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:log_models/log_models.dart';
import 'package:log_parser/log_parser.dart';
import 'package:log_viewer_bloc/log_viewer_bloc.dart';
import 'package:log_viewer_widgets/log_viewer_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../destination.dart';

TextStyle _codeTextStyle({
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
    color: color,
    height: height,
  );
}

BoxDecoration _panelDecoration(ThemeData theme, {bool emphasized = false}) {
  final colorScheme = theme.colorScheme;

  return BoxDecoration(
    color: emphasized
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: emphasized
          ? colorScheme.outline.withValues(alpha: 0.24)
          : colorScheme.outlineVariant,
    ),
    boxShadow: [
      BoxShadow(
        color: colorScheme.shadow.withValues(alpha: emphasized ? 0.10 : 0.05),
        blurRadius: emphasized ? 32 : 20,
        offset: Offset(0, emphasized ? 18 : 10),
      ),
    ],
  );
}

class LogViewerScreen extends StatelessWidget {
  static const name = 'Log Viewer';
  static const path = '/log-viewer';

  const LogViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedPrefs = context.read<SharedPreferences>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LogFileBloc()),
        BlocProvider(create: (_) => FilterBloc(sharedPreferences: sharedPrefs)),
        BlocProvider(create: (_) => SelectionBloc()),
      ],
      child: const _LogViewerBody(),
    );
  }
}

class _LogViewerBody extends StatelessWidget {
  const _LogViewerBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DmAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(LogViewerScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      appBar: AppBar(
        toolbarHeight: 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('JSON Log Inspector'),
            const SizedBox(height: 2),
            Text(
              'Open, filter, and inspect structured request traces',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: (context) => SafeArea(
        child: BlocBuilder<LogFileBloc, LogFileState>(
          builder: (context, fileState) {
            if (fileState.status == LogFileStatus.initial) {
              return _InitialView(
                onFileOpened: (path) {
                  context.read<LogFileBloc>().add(FileOpened(path));
                },
              );
            }

            if (fileState.status == LogFileStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (fileState.status == LogFileStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(24),
                    decoration: _panelDecoration(
                      Theme.of(context),
                      emphasized: true,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fileState.errorMessage ?? 'Unknown error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            context.read<LogFileBloc>().add(const Cleared());
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return _LoadedView(fileState: fileState);
          },
        ),
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView({required this.onFileOpened});

  final void Function(String path) onFileOpened;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.72),
              colorScheme.secondaryContainer.withValues(alpha: 0.36),
              colorScheme.surface,
            ],
          ),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: _panelDecoration(theme, emphasized: true),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 44,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Open a JSONL log file to inspect',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Load `.jsonl`, `.json`, or `.log` files and drill into request, response, header, and body pairs without leaving the workspace.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _pickFile(context),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open File'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jsonl', 'json', 'log'],
    );

    if (result != null && result.files.single.path != null) {
      onFileOpened(result.files.single.path!);
    }
  }
}

class _LoadedView extends StatefulWidget {
  const _LoadedView({required this.fileState});

  final LogFileState fileState;

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  LogRecord? _selectedRecord;
  LogRecord? _pairedRecord;
  int? _selectedLineIndex;

  @override
  Widget build(BuildContext context) {
    final index = widget.fileState.index!;
    final entryReader = widget.fileState.entryReader!;
    final filteredIndices = widget.fileState.filteredIndices;
    final displayIndices =
        filteredIndices ?? List.generate(index.totalLines, (i) => i);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 920;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          _Toolbar(
            fileState: widget.fileState,
            displayCount: displayIndices.length,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isWide
                ? _DesktopLayout(
                    displayIndices: displayIndices,
                    entryReader: entryReader,
                    index: index,
                    selectedLineIndex: _selectedLineIndex,
                    selectedRecord: _selectedRecord,
                    pairedRecord: _pairedRecord,
                    onEntrySelected: (lineIndex, record, paired) {
                      if (!mounted) return;
                      setState(() {
                        _selectedLineIndex = lineIndex;
                        _selectedRecord = record;
                        _pairedRecord = paired;
                      });
                    },
                  )
                : _MobileLayout(
                    displayIndices: displayIndices,
                    entryReader: entryReader,
                    index: index,
                  ),
          ),
          const SizedBox(height: 12),
          _StatusBar(
            filePath: widget.fileState.filePath ?? '',
            totalLines: index.totalLines,
            validLines: index.validLines,
            shownLines: displayIndices.length,
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatefulWidget {
  const _Toolbar({required this.fileState, required this.displayCount});

  final LogFileState fileState;
  final int displayCount;

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  int _filterGeneration = 0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FilterBloc, FilterState>(
      listener: (context, filterState) {
        _applyFilters(context, filterState);
      },
      builder: (context, filterState) {
        final theme = Theme.of(context);
        final fileName = (widget.fileState.filePath ?? '')
            .split(RegExp(r'[/\\]'))
            .last;
        final compact = MediaQuery.of(context).size.width < 1100;

        return Container(
          decoration: _panelDecoration(theme, emphasized: true),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                _ToolbarHeader(
                  fileName: fileName,
                  displayCount: widget.displayCount,
                  activeFilterCount: filterState.rules
                      .where((e) => e.enabled)
                      .length,
                ),
                const SizedBox(height: 16),
                FilterBar(
                  onFilterAdded: (rule) {
                    context.read<FilterBloc>().add(RuleAdded(rule));
                  },
                  onSearchChanged: (query) {
                    context.read<FilterBloc>().add(SearchChanged(query));
                  },
                  activeRules: filterState.rules,
                  onRuleToggled: (id) {
                    context.read<FilterBloc>().add(RuleToggled(id));
                  },
                  onRuleRemoved: (id) {
                    context.read<FilterBloc>().add(RuleRemoved(id));
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openFile(context),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open File'),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Filter'),
                      onPressed: () => _showFilterRuleBuilder(context),
                    ),
                    _PresetsDropdown(
                      presets: filterState.presets,
                      onPresetApplied: (preset) {
                        context.read<FilterBloc>().add(PresetApplied(preset));
                      },
                      onPresetSaved: () {
                        _showSavePresetDialog(context);
                      },
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ToolbarHeader(
                      fileName: fileName,
                      displayCount: widget.displayCount,
                      activeFilterCount: filterState.rules
                          .where((e) => e.enabled)
                          .length,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilterBar(
                        onFilterAdded: (rule) {
                          context.read<FilterBloc>().add(RuleAdded(rule));
                        },
                        onSearchChanged: (query) {
                          context.read<FilterBloc>().add(SearchChanged(query));
                        },
                        activeRules: filterState.rules,
                        onRuleToggled: (id) {
                          context.read<FilterBloc>().add(RuleToggled(id));
                        },
                        onRuleRemoved: (id) {
                          context.read<FilterBloc>().add(RuleRemoved(id));
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openFile(context),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Open File'),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Filter'),
                          onPressed: () => _showFilterRuleBuilder(context),
                        ),
                        const SizedBox(height: 10),
                        _PresetsDropdown(
                          presets: filterState.presets,
                          onPresetApplied: (preset) {
                            context.read<FilterBloc>().add(
                              PresetApplied(preset),
                            );
                          },
                          onPresetSaved: () {
                            _showSavePresetDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jsonl', 'json', 'log'],
    );
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<LogFileBloc>().add(FileOpened(result.files.single.path!));
    }
  }

  void _showFilterRuleBuilder(BuildContext context) {
    final keyPaths = widget.fileState.keyPaths;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FilterRuleBuilder(
              availableKeyPaths: keyPaths,
              onRuleCreated: (rule) {
                context.read<FilterBloc>().add(RuleAdded(rule));
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        );
      },
    );
  }

  void _showSavePresetDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save Filter Preset'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Preset Name'),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                context.read<FilterBloc>().add(PresetSaved(value.trim()));
                Navigator.of(dialogContext).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<FilterBloc>().add(PresetSaved(name));
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  void _applyFilters(BuildContext context, FilterState filterState) {
    final logFileBloc = context.read<LogFileBloc>();
    final state = logFileBloc.state;

    if (state.index == null || state.filePath == null) {
      return;
    }

    final generation = ++_filterGeneration;

    FilterEngine.buildFilteredIndex(
      filePath: state.filePath!,
      index: state.index!,
      rules: filterState.rules,
      searchQuery: filterState.searchQuery,
    ).then((filtered) {
      if (_filterGeneration == generation && mounted) {
        logFileBloc.add(FilterApplied(filtered));
      }
    });
  }
}

class _ToolbarHeader extends StatelessWidget {
  const _ToolbarHeader({
    required this.fileName,
    required this.displayCount,
    required this.activeFilterCount,
  });

  final String fileName;
  final int displayCount;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workspace', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            fileName.isEmpty ? 'No file loaded' : fileName,
            style: theme.textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToolbarBadge(
                icon: Icons.dataset_outlined,
                label: '$displayCount visible',
              ),
              _ToolbarBadge(
                icon: Icons.filter_alt_outlined,
                label: '$activeFilterCount active',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarBadge extends StatelessWidget {
  const _ToolbarBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.displayIndices,
    required this.entryReader,
    required this.index,
    required this.selectedLineIndex,
    required this.selectedRecord,
    required this.pairedRecord,
    required this.onEntrySelected,
  });

  final List<int> displayIndices;
  final EntryReader entryReader;
  final FileIndexResult index;
  final int? selectedLineIndex;
  final LogRecord? selectedRecord;
  final LogRecord? pairedRecord;
  final void Function(int lineIndex, LogRecord record, LogRecord? paired)
  onEntrySelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _SurfacePanel(
            title: 'Timeline',
            subtitle: '${displayIndices.length} matching entries',
            child: _LogList(
              displayIndices: displayIndices,
              entryReader: entryReader,
              index: index,
              selectedLineIndex: selectedLineIndex,
              onEntrySelected: onEntrySelected,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 7,
          child: _SurfacePanel(
            title: selectedRecord == null ? 'Detail' : 'Entry Detail',
            subtitle: selectedRecord == null
                ? 'Choose a timeline item to inspect headers and body'
                : 'Expanded request and response context',
            child: selectedRecord != null
                ? DetailPanel(
                    record: selectedRecord!,
                    pairedRecord: pairedRecord,
                  )
                : const _EmptyDetailState(),
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.displayIndices,
    required this.entryReader,
    required this.index,
  });

  final List<int> displayIndices;
  final EntryReader entryReader;
  final FileIndexResult index;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      title: 'Timeline',
      subtitle: '${displayIndices.length} matching entries',
      child: _LogList(
        displayIndices: displayIndices,
        entryReader: entryReader,
        index: index,
        selectedLineIndex: null,
        onEntrySelected: (lineIndex, record, paired) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Entry Detail')),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      decoration: _panelDecoration(Theme.of(context)),
                      child: DetailPanel(record: record, pairedRecord: paired),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: _panelDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EmptyDetailState extends StatelessWidget {
  const _EmptyDetailState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.preview_outlined,
                color: theme.colorScheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an entry to view details',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The request, response, headers, and parsed JSON body will appear here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogList extends StatefulWidget {
  const _LogList({
    required this.displayIndices,
    required this.entryReader,
    required this.index,
    required this.selectedLineIndex,
    required this.onEntrySelected,
  });

  final List<int> displayIndices;
  final EntryReader entryReader;
  final FileIndexResult index;
  final int? selectedLineIndex;
  final void Function(int lineIndex, LogRecord record, LogRecord? paired)
  onEntrySelected;

  @override
  State<_LogList> createState() => _LogListState();
}

class _LogListState extends State<_LogList> {
  final _futureCache = <int, Future<String>>{};

  @override
  void didUpdateWidget(_LogList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entryReader != widget.entryReader ||
        oldWidget.displayIndices != widget.displayIndices) {
      _futureCache.clear();
    }
  }

  Future<String> _getCachedFuture(int lineIndex) {
    return _futureCache.putIfAbsent(lineIndex, () {
      if (_futureCache.length > 500) {
        final keysToRemove = _futureCache.keys.take(100).toList();
        for (final key in keysToRemove) {
          _futureCache.remove(key);
        }
      }
      return widget.entryReader.readRawLine(lineIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      itemCount: widget.displayIndices.length,
      itemExtent: 78,
      itemBuilder: (context, i) {
        final lineIndex = widget.displayIndices[i];
        return FutureBuilder<String>(
          future: _getCachedFuture(lineIndex),
          builder: (context, snapshot) {
            final rawLine = snapshot.data ?? '...';
            return LogListTile(
              rawLine: rawLine,
              index: lineIndex,
              isSelected: lineIndex == widget.selectedLineIndex,
              onTap: () => _selectEntry(lineIndex),
            );
          },
        );
      },
    );
  }

  Future<void> _selectEntry(int lineIndex) async {
    final record = await widget.entryReader.readEntry(lineIndex);
    if (record == null || !mounted) return;

    LogRecord? paired;
    if (record.recordType == 'request' || record.recordType == 'response') {
      final pairIndices = widget.index.requestIdMap[record.requestId];
      if (pairIndices != null) {
        for (final pairIdx in pairIndices) {
          if (pairIdx != lineIndex) {
            paired = await widget.entryReader.readEntry(pairIdx);
            break;
          }
        }
      }
    }

    context.read<SelectionBloc>().add(
      EntrySelected(index: lineIndex, record: record, pairedRecord: paired),
    );
    widget.onEntrySelected(lineIndex, record, paired);
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.filePath,
    required this.totalLines,
    required this.validLines,
    required this.shownLines,
  });

  final String filePath;
  final int totalLines;
  final int validLines;
  final int shownLines;

  @override
  Widget build(BuildContext context) {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(Theme.of(context)),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatusChip(icon: Icons.insert_drive_file_outlined, label: fileName),
          _StatusChip(icon: Icons.subject_outlined, label: '$totalLines lines'),
          _StatusChip(
            icon: Icons.verified_outlined,
            label: '$validLines valid',
          ),
          _StatusChip(
            icon: Icons.visibility_outlined,
            label: '$shownLines shown',
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: _codeTextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetsDropdown extends StatelessWidget {
  const _PresetsDropdown({
    required this.presets,
    required this.onPresetApplied,
    required this.onPresetSaved,
  });

  final List<FilterPreset> presets;
  final void Function(FilterPreset preset) onPresetApplied;
  final VoidCallback onPresetSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<Object>(
      tooltip: 'Filter Presets',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Presets',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return [
          ...presets.map(
            (preset) => PopupMenuItem<FilterPreset>(
              value: preset,
              child: Text(preset.name),
            ),
          ),
          if (presets.isNotEmpty) const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: '_save',
            child: Row(
              children: [
                Icon(Icons.save, size: 16),
                SizedBox(width: 8),
                Text('Save Current as Preset'),
              ],
            ),
          ),
        ];
      },
      onSelected: (value) {
        if (value is FilterPreset) {
          onPresetApplied(value);
        } else if (value == '_save') {
          onPresetSaved();
        }
      },
    );
  }
}
