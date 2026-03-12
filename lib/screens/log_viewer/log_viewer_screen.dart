import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:log_models/log_models.dart';
import 'package:log_parser/log_parser.dart';
import 'package:log_viewer_bloc/log_viewer_bloc.dart';
import 'package:log_viewer_widgets/log_viewer_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../destination.dart';

class LogViewerScreen extends StatelessWidget {
  static const name = 'Log Viewer';
  static const path = '/';

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
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(LogViewerScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      appBar: AppBar(
        title: const Text('JSON Log Inspector'),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(fileState.errorMessage ?? 'Unknown error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        context.read<LogFileBloc>().add(const Cleared());
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Open a JSONL log file to inspect',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _pickFile(context),
            icon: const Icon(Icons.folder_open),
            label: const Text('Open File'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final index = widget.fileState.index!;
    final entryReader = widget.fileState.entryReader!;
    final filteredIndices = widget.fileState.filteredIndices;
    final displayIndices =
        filteredIndices ?? List.generate(index.totalLines, (i) => i);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Column(
      children: [
        // Toolbar
        _Toolbar(
          fileState: widget.fileState,
          displayCount: displayIndices.length,
        ),
        // Main content
        Expanded(
          child: isWide
              ? _DesktopLayout(
                  displayIndices: displayIndices,
                  entryReader: entryReader,
                  index: index,
                  selectedRecord: _selectedRecord,
                  pairedRecord: _pairedRecord,
                  onEntrySelected: (record, paired) {
                    if (!mounted) return;
                    setState(() {
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
        // Status bar
        _StatusBar(
          filePath: widget.fileState.filePath ?? '',
          totalLines: index.totalLines,
          validLines: index.validLines,
          shownLines: displayIndices.length,
        ),
      ],
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Open File button
                  IconButton(
                    icon: const Icon(Icons.folder_open, size: 20),
                    tooltip: 'Open File',
                    onPressed: () => _openFile(context),
                  ),
                  const SizedBox(width: 4),
                  // Filter and search bar
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
                  const SizedBox(width: 4),
                  // + Add Filter button
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Filter'),
                    onPressed: () => _showFilterRuleBuilder(context),
                  ),
                  const SizedBox(width: 4),
                  // Presets dropdown
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
    if (result != null && result.files.single.path != null) {
      if (context.mounted) {
        context.read<LogFileBloc>().add(FileOpened(result.files.single.path!));
      }
    }
  }

  void _showFilterRuleBuilder(BuildContext context) {
    final keyPaths = widget.fileState.keyPaths;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
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
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save Filter Preset'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Preset Name',
              border: OutlineInputBorder(),
            ),
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

    if (state.index == null || state.filePath == null) return;

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

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.displayIndices,
    required this.entryReader,
    required this.index,
    required this.selectedRecord,
    required this.pairedRecord,
    required this.onEntrySelected,
  });

  final List<int> displayIndices;
  final EntryReader entryReader;
  final FileIndexResult index;
  final LogRecord? selectedRecord;
  final LogRecord? pairedRecord;
  final void Function(LogRecord record, LogRecord? paired) onEntrySelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Master list
        Expanded(
          flex: 2,
          child: _LogList(
            displayIndices: displayIndices,
            entryReader: entryReader,
            index: index,
            onEntrySelected: onEntrySelected,
          ),
        ),
        const VerticalDivider(width: 1),
        // Detail panel
        Expanded(
          flex: 3,
          child: selectedRecord != null
              ? DetailPanel(record: selectedRecord!, pairedRecord: pairedRecord)
              : const Center(child: Text('Select an entry to view details')),
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
    return _LogList(
      displayIndices: displayIndices,
      entryReader: entryReader,
      index: index,
      onEntrySelected: (record, paired) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Entry Detail')),
              body: DetailPanel(record: record, pairedRecord: paired),
            ),
          ),
        );
      },
    );
  }
}

class _LogList extends StatefulWidget {
  const _LogList({
    required this.displayIndices,
    required this.entryReader,
    required this.index,
    required this.onEntrySelected,
  });

  final List<int> displayIndices;
  final EntryReader entryReader;
  final FileIndexResult index;
  final void Function(LogRecord record, LogRecord? paired) onEntrySelected;

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
      itemCount: widget.displayIndices.length,
      itemExtent: 48,
      itemBuilder: (context, i) {
        final lineIndex = widget.displayIndices[i];
        return FutureBuilder<String>(
          future: _getCachedFuture(lineIndex),
          builder: (context, snapshot) {
            final rawLine = snapshot.data ?? '...';
            return LogListTile(
              rawLine: rawLine,
              index: lineIndex,
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

    widget.onEntrySelected(record, paired);
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text(fileName, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 16),
          Text(
            '$totalLines lines',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Text(
            '$validLines valid',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Text(
            '$shownLines shown',
            style: Theme.of(context).textTheme.bodySmall,
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
    return PopupMenuButton<Object>(
      tooltip: 'Filter Presets',
      icon: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, size: 18),
          SizedBox(width: 4),
          Text('Presets'),
          Icon(Icons.arrow_drop_down, size: 18),
        ],
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
