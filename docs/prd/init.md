# JSON Log Inspector — Product Requirements Document

**Version:** 1.0
**Date:** 2026-03-13
**Status:** Ready for implementation

---

## Overview

JSON Log Inspector is a cross-platform Flutter application for viewing and debugging JSONL log files produced by [caddy-reverse-proxy-dump](https://github.com/gsmlg-dev/caddy-reverse-proxy-dump). It provides a Dadroit-inspired browsing experience with structured filtering, SSE record pairing, and JSON body inspection — optimized for API traffic analysis.

Built as a new standalone app from the [flutter-app-template](https://github.com/gsmlg-app/flutter-app-template) monorepo using BLoC pattern, Melos workspace, and Mason code generation.

**Platforms:** Desktop (macOS, Linux) primary, mobile (Android, iOS) secondary.

---

## Data Source

### LogRecord Schema (caddy-reverse-proxy-dump output)

Each JSONL line is a `LogRecord` with this structure:

```
ts              string    ISO 8601 timestamp
request_id      string    Unique ID, shared between paired SSE records
record_type     string    "exchange" | "request" | "response"
duration_ms     float     Round-trip time (exchange only)
request
  method        string    HTTP method
  scheme        string    "https" | "http"
  host          string    Target host
  uri           string    Request path + query
  proto         string    "HTTP/2.0" etc.
  remote_addr   string    Client IP:port
  headers       Map       Header name → List<String>
  body          string    Raw or base64-encoded body
  body_encoding string    "text" | "base64"
  body_truncated bool     Whether max_capture_bytes was exceeded
  content_type  string    Detected content type
  content_length int      Body size in bytes
response
  status        int       HTTP status code
  headers       Map       Header name → List<String>
  body          string    Raw or base64-encoded body
  body_encoding string    "text" | "base64"
  body_truncated bool
  content_type  string
```

### Record Types

- **`exchange`** — Complete request/response pair in a single record. Most common.
- **`request`** + **`response`** — SSE streams emit two separate records sharing the same `request_id`. The viewer must pair these by `request_id` and present them as a unified exchange.

---

## Architecture

### Package Decomposition (Melos monorepo)

| Package | Location | Responsibility |
|---|---|---|
| `log_models` | `app_lib/log_models/` | `LogRecord`, `RequestData`, `ResponseData`, `FilterRule`, `FilterPreset` — pure Dart, immutable, no Flutter dependency |
| `log_parser` | `app_lib/log_parser/` | Lazy JSONL streaming, line-by-line parsing, SSE record pairing by `request_id`, key-path discovery |
| `log_bloc` | `app_bloc/log_viewer/` | `LogFileBloc`, `FilterBloc`, `SelectionBloc` |
| `log_widgets` | `app_widget/log_viewer/` | `JsonTreeView`, `LogListTile`, `FilterBar`, `FilterRuleBuilder`, `BodyViewer` |
| Main screen | `lib/screens/log_viewer/` | Composes widgets + blocs into master-detail layout |

### Theme

Uses the template's existing theme system (fire, green, violet, wheat) with dynamic switching via `theme_bloc`. No custom theme work needed — the log viewer inherits the active scheme.

### State Management

BLoC pattern per the template convention. Three blocs:

**LogFileBloc**
- Events: `FileOpened(path)`, `Cleared`
- States: `Initial`, `Loading(progress)`, `Loaded(metadata)`, `Error(message)`
- Does NOT hold all entries in memory — manages the lazy stream handle and file metadata only

**FilterBloc**
- Events: `RuleAdded`, `RuleRemoved`, `RuleToggled`, `RuleUpdated`, `SearchChanged(query)`, `PresetApplied(preset)`, `PresetSaved(name)`
- State: `FilterState(rules: List<FilterRule>, searchQuery: String, presets: List<FilterPreset>)`
- Presets persisted via `shared_preferences`

**SelectionBloc**
- Events: `EntrySelected(index)`, `SelectionCleared`
- State: `SelectionState(selectedRecord: LogRecord?, pairedRecord: LogRecord?)`
- When selecting an SSE `request` record, automatically resolves the paired `response` record (and vice versa)

---

## Lazy Streaming Strategy

The viewer never loads the full file into memory. This is critical for 50MB+ files.

### Approach

1. **Index pass** — On file open, stream through the file line-by-line building a lightweight index: `List<(offset: int, length: int)>` mapping line number to byte offset + length. Also collect: total line count, valid/invalid counts, and key-path set (from first 100 entries).

2. **On-demand read** — When the virtualized list needs to render a row, read that specific line from disk by offset. Parse on read. Cache recently accessed entries (LRU, ~500 entries).

3. **Filtering** — Re-stream the index, parsing each line and testing against active filter rules. Build a filtered index (`List<int>` of matching line numbers). This runs in an isolate for large files.

4. **SSE pairing** — During the index pass, build a secondary map: `Map<String, List<int>>` keyed by `request_id` pointing to line indices. Records with the same `request_id` are paired. Most entries will have a single line; SSE streams will have two.

### Isolate Boundary

All parsing and filtering runs in a separate isolate via `Isolate.run()` or `compute()`. The main isolate only holds the index and the LRU cache. Communication is via message passing of index data, never full entry lists.

---

## User Interface

### Layout — Desktop

```
┌─────────────────────────────────────────────────────────┐
│ [Open File]  [🔍 Search... ]  [+ Add Filter]  [Presets ▾] │
├─────────────────────────┬───────────────────────────────┤
│  Log List (master)      │  Detail Panel                 │
│                         │                               │
│  {"ts":"2026-03-11...   │  ┌─ REQUEST ───────────────┐  │
│  {"ts":"2026-03-11...   │  │ POST /api/v1/messages    │  │
│ >{"ts":"2026-03-11...   │  │ ▾ headers:               │  │
│  {"ts":"2026-03-11...   │  │   Content-Type: app/json │  │
│  ...                    │  │ ▾ body: (pretty JSON)    │  │
│                         │  │   { "model": "claude..." │  │
│  (virtualized)          │  ├─ RESPONSE ──────────────┤  │
│                         │  │ 200 OK  42ms             │  │
│                         │  │ ▾ headers:               │  │
│                         │  │ ▾ body: (pretty JSON)    │  │
│                         │  │   { "id": "msg_01..." }  │  │
│                         │  └─────────────────────────┘  │
├─────────────────────────┴───────────────────────────────┤
│ dump.jsonl │ 12,847 lines │ 12,803 valid │ 4,291 shown │
└─────────────────────────────────────────────────────────┘
```

### Layout — Mobile

Push navigation: list screen → detail screen. Same components, sequential flow instead of side-by-side.

### List View

Each row displays the raw one-line JSON preview, truncated to fit. Selected row is highlighted. Invalid lines (parse errors) shown with error indicator.

The list is fully virtualized via `ListView.builder` backed by the filtered index. Only visible rows trigger disk reads + parsing.

### Detail Panel — Stacked Layout

For a selected record (or paired SSE records), the detail panel shows:

**Request section** (top)
- Summary line: `METHOD uri` + `proto`
- Collapsible JSON tree for the full `request` object
- Body sub-section: if `content_type` contains `json`, render body as pretty-printed + syntax-highlighted JSON tree. Otherwise, render as monospaced text. If `body_truncated` is true, show indicator.

**Response section** (below, scrollable)
- Summary line: `status` + `duration_ms`
- Collapsible JSON tree for the full `response` object
- Body sub-section: same content-type-aware rendering as request

Both sections are independently collapsible. The entire panel scrolls as one unit.

### JSON Tree Widget

Recursive expand/collapse widget. Each node shows key name, value type indicator (color-coded), and value preview. Map and List nodes are collapsible. Leaf values are copyable on tap/click.

Syntax highlighting by type:
- Strings → theme accent color
- Numbers → distinct color
- Booleans → distinct color
- Null → muted/grey
- Keys → bold

### Body Viewer

Content-type-aware rendering:
- `application/json` → parse string body and render as nested JSON tree (pretty-printed, syntax-highlighted)
- `text/*` → monospaced text block
- `base64` encoded bodies → show "[base64 binary, N bytes]" placeholder (no decode in M1)

---

## Filter System

### Dual UX

**Quick filter bar** — Text input accepting `key:operator:value` syntax for power users:
- `request.method:==:POST`
- `response.status:>=:400`
- `request.uri:contains:/api/v2`
- `record_type:==:exchange`
- `duration_ms:>:1000`

Pressing Enter adds the rule. Multiple rules compose with AND logic.

**Visual rule builder** — Opened via "+ Add Filter" button. Three dropdowns:
1. Key path — autocomplete from discovered keys (sampled from first 100 entries)
2. Operator — `==`, `!=`, `contains`, `>`, `<`, `>=`, `<=`, `exists`, `regex`
3. Value — free text input

### Filter Rules

Each rule has: `id`, `keyPath`, `operator`, `value`, `enabled` (toggle). Active rules shown as chips below the toolbar. Click chip to toggle, long-press/right-click to edit or remove.

### Filter Presets

Named collections of filter rules. Saved to `shared_preferences`. Built-in defaults:
- "Errors only" → `response.status:>=:400`
- "Slow requests" → `duration_ms:>:1000`
- "SSE streams" → `record_type:!=:exchange`

### Full-Text Search

Separate from filter rules. Searches across the raw JSON line. Runs concurrently with filter rules (both must match). Debounced input (300ms).

---

## Key-Path Discovery

On file open, during the index pass, sample the first 100 valid entries. Recursively walk parsed maps collecting all dot-separated key paths. Deduplicate and sort. This set feeds:
- Filter rule builder autocomplete
- Quick filter bar suggestions

Known top-level paths from the schema are always included even if not found in sample:
`ts`, `request_id`, `record_type`, `duration_ms`, `request.method`, `request.uri`, `request.host`, `response.status`, `request.content_type`, `response.content_type`

---

## File Input

### Desktop
- File picker dialog (`file_picker` package), filtered to `.jsonl` and `.json` extensions
- Drag-and-drop onto the app window (if supported by platform, otherwise deferred)

### Mobile
- File picker dialog
- Share sheet / "Open with" integration for `.jsonl` files (platform-specific URI handling)

No stdin, no network sources, no live tail in M1.

---

## Mason Brick

Generate the initial bloc scaffold:

```bash
mason make simple_bloc -o app_bloc/log_viewer --name=log_viewer
```

Then manually decompose into `LogFileBloc`, `FilterBloc`, `SelectionBloc` following the event/state contracts above.

---

## Non-Goals (M1)

- Live tail / file watching
- Network input (TCP, WebSocket)
- Stdin pipe reading
- Base64 body decoding/display
- Bookmarking entries
- Diffing request/response pairs
- Export / share filtered results
- Multi-file comparison

---

## Milestones

| Phase | Scope | Exit Criteria |
|---|---|---|
| **M1 — Core Viewer** | File open, lazy streaming index, virtualized list with raw JSON preview, detail panel with stacked request/response, JSON tree expand/collapse, SSE record pairing | Can open a 50MB+ dump file without OOM, browse entries, inspect paired SSE exchanges |
| **M2 — Filter & Search** | Quick filter bar, visual rule builder, filter presets, full-text search, key-path autocomplete | Can filter by status >= 400, search for a URI, save/load presets |
| **M3 — Body Intelligence** | JSON body pretty-printing, syntax highlighting by content_type, body truncation indicators | JSON API bodies render as navigable trees, not raw strings |
| **M4 — Mobile & Polish** | Responsive layout, share sheet integration, drag-drop on desktop, performance tuning for 100k+ line files | Usable on Android/iOS with push navigation |