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
      allowedExtensions: ['jsonl', 'json'],
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

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.fileState, required this.displayCount});

  final LogFileState fileState;
  final int displayCount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, filterState) {
        return FilterBar(
          onFilterAdded: (rule) {
            context.read<FilterBloc>().add(RuleAdded(rule));
            _applyFilters(context);
          },
          onSearchChanged: (query) {
            context.read<FilterBloc>().add(SearchChanged(query));
            _applyFilters(context);
          },
          activeRules: filterState.rules,
          onRuleToggled: (id) {
            context.read<FilterBloc>().add(RuleToggled(id));
            _applyFilters(context);
          },
          onRuleRemoved: (id) {
            context.read<FilterBloc>().add(RuleRemoved(id));
            _applyFilters(context);
          },
        );
      },
    );
  }

  void _applyFilters(BuildContext context) {
    final logFileBloc = context.read<LogFileBloc>();
    final filterBloc = context.read<FilterBloc>();
    final state = logFileBloc.state;

    if (state.index == null || state.filePath == null) return;

    FilterEngine.buildFilteredIndex(
      filePath: state.filePath!,
      index: state.index!,
      rules: filterBloc.state.rules.where((r) => r.enabled).toList(),
      searchQuery: filterBloc.state.searchQuery,
    ).then((filtered) {
      logFileBloc.add(FilterApplied(filtered));
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

class _LogList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: displayIndices.length,
      itemBuilder: (context, i) {
        final lineIndex = displayIndices[i];
        return FutureBuilder<String>(
          future: entryReader.readRawLine(lineIndex),
          builder: (context, snapshot) {
            final rawLine = snapshot.data ?? '...';
            return LogListTile(
              rawLine: rawLine,
              index: lineIndex,
              onTap: () => _selectEntry(context, lineIndex),
            );
          },
        );
      },
    );
  }

  Future<void> _selectEntry(BuildContext context, int lineIndex) async {
    final record = await entryReader.readEntry(lineIndex);
    if (record == null) return;

    LogRecord? paired;
    if (record.recordType == 'request' || record.recordType == 'response') {
      final pairIndices = index.requestIdMap[record.requestId];
      if (pairIndices != null) {
        for (final pairIdx in pairIndices) {
          if (pairIdx != lineIndex) {
            paired = await entryReader.readEntry(pairIdx);
            break;
          }
        }
      }
    }

    onEntrySelected(record, paired);
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
    final fileName = filePath.split('/').last;
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
