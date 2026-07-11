# Local Gallery

Desktop-first local photo and video gallery for Windows and macOS, built with
Flutter and Riverpod.

## MVP status

Implemented:

- persisted root-folder selection (`file_picker` + `shared_preferences`)
- browsing direct children of folders
- image, video, and folder models
- folder cards with up to four lightweight image previews
- virtualized grid plus incremental batches of 60 items
- A–Z, Z–A, newest, and oldest sorting
- image detail with pan/zoom
- on-demand `media_kit` video playback with custom controls
- generated video-card previews with bounded concurrent extraction
- previous/next media with natural filename ordering
- keyboard and cross-platform gamepad controls
- native fullscreen on Windows and macOS
- persistent macOS folder access through security-scoped bookmarks
- expandable folder/media sidebar with active-item auto-reveal
- loading, empty, and error states

Planned after the MVP is validated: recursive indexing, Drift/Isar metadata
cache, persistent disk thumbnails, debounced `watcher` updates, and additional
large-library performance work.

## Controls

Keyboard shortcuts are active in media detail unless a row explicitly mentions
the gallery.

### Keyboard

| Key | Action |
| --- | --- |
| `Arrow Up` | Previous media |
| `Arrow Down` | Next media |
| `Arrow Left` | Seek video backward 3 seconds |
| `Arrow Right` | Seek video forward 3 seconds |
| `Space` | Play or pause video |
| `M` | Mute or unmute video |
| `F` | Enter or leave native fullscreen |
| `S` | Show or hide the sidebar in gallery and media detail |
| `Escape` | Leave fullscreen first; otherwise return to the gallery |

Completed videos automatically advance to the next video in the current
folder. Images between two videos are skipped for automatic advancement, while
manual previous/next continues to navigate every media item.

### Gamepad

Gamepad input uses normalized Xbox-style names. The PlayStation equivalent is
included in parentheses.

| Gamepad input | Action |
| --- | --- |
| D-pad Up or `LB` (`L1`) | Previous media |
| D-pad Down or `RB` (`R1`) | Next media |
| D-pad Left | Seek video backward 3 seconds |
| D-pad Right | Seek video forward 3 seconds |
| Left stick Up/Down | Previous/next media |
| Left stick Left/Right | Seek backward/forward 3 seconds |
| `A` (`Cross`) | Play or pause video |
| `X` (`Square`) | Mute or unmute video |
| `Y` (`Triangle`) or Start | Enter or leave native fullscreen |
| Back/Select/Share or Touchpad | Show or hide the sidebar |
| `B` (`Circle`) | Leave fullscreen; otherwise return to the gallery |

The left analog stick uses a dead zone and triggers once per directional push.
Return the stick near its center before triggering the same axis again. Home,
triggers, and stick-click buttons are currently unassigned.

## Architecture

The project uses feature-first Riverpod with a small Controller → Repository →
Service chain. It intentionally avoids use-case/interactor and domain mapping
layers until they solve a demonstrated problem.

```text
lib/
  app/
    app.dart                 # MaterialApp composition
    theme.dart               # application theme
  shared/
    models/
      gallery_item.dart      # GalleryItem, GalleryFolder, MediaItem
      gallery_sort.dart      # shared ordering contract
  features/
    gallery/
      gallery_page.dart      # grid and folder navigation UI
      gallery_controller.dart
      gallery_state.dart
      gallery_repository.dart
      gallery_service.dart   # filesystem access and extension filtering
      widgets/gallery_card.dart
    media_detail/
      media_detail_page.dart
      media_detail_controller.dart
      media_detail_state.dart
    settings/
      settings_controller.dart
      settings_state.dart
      settings_repository.dart
    media_index/             # stage-two interfaces
      media_index_service.dart
      thumbnail_service.dart
      file_watcher_service.dart
```

### Responsibilities

- **UI** renders state, forwards user intent, and owns short-lived visual state.
- **Controller + State** coordinate a feature: loading, navigation, sorting,
  pagination, and player lifecycle. Controllers do not perform raw filesystem
  or preferences access.
- **Repository** is the stable data boundary. Today it delegates to a filesystem
  scan; later it can combine cached metadata with fresh filesystem facts without
  changing controllers.
- **Service** talks to platform-facing APIs such as `dart:io`, media playback,
  thumbnail generation, and filesystem events.
- **Shared models** describe data crossing feature boundaries. They stay as
  plain immutable Dart objects and contain no persistence annotations yet.

`GalleryItem` is the sealed base type. `GalleryFolder` contains zero to four
preview paths; `MediaItem` represents an image or video and carries filesystem
metadata. `GallerySort` is shared by gallery and detail so one ordered list can
drive the grid, sidebar, and previous/next navigation. `GalleryState` owns the
current directory and visible batch. `MediaDetailState` owns the active index
and playback facts.

## Data flow

```text
Directory / watcher event
  → GalleryService (read and normalize filesystem entries)
  → metadata cache (stage two: return cached rows, upsert changed rows)
  → GalleryRepository (single read API and cache policy)
  → GalleryController (sort, batch, loading/error state)
  → Grid/sidebar UI (builder virtualization)
```

For stage two, the initial root index is persisted by stable canonical path.
Watcher events are debounced and grouped by parent directory. Create/update
events stat and upsert only affected entries; delete events remove only affected
rows. The controller patches the current ordered list and only falls back to a
directory rescan when event semantics are ambiguous (for example, an unmatched
rename pair).

## Roadmap

1. **MVP foundation (current):** choose/persist root, browse one directory at a
   time, builder grid, image/video detail, custom basic playback controls.
2. **MVP hardening (in progress):** expand controller/widget tests, improve
   inaccessible-folder recovery, and validate keyboard/gamepad behavior across
   supported controller models.
3. **Index/cache:** add Drift (preferred for queryable sort/pagination) or Isar,
   store path/type/size/mtime/dimensions/duration, and scan on a worker isolate.
4. **Realtime updates:** use `watcher` with a 200–400 ms debounce, incrementally
   patch repository/cache/state, and reconcile uncertain rename events.
5. **Thumbnails:** store bounded-size thumbnails under `path_provider` cache,
   key by canonical path + mtime + size, prioritize visible items, and limit
   concurrent decoding.
6. **Large-library UX:** repository-backed cursor pagination, folder tree/sidebar,
   active-item auto-scroll, cancellable scans, skeleton polish, and cache limits.

Each stage should stay runnable. Do not add recursive indexing and watcher
mutation in the same change: first make cached reads authoritative, then feed
incremental events into that tested boundary.

## Run

```sh
flutter pub get
flutter run -d macos
# or on Windows
flutter run -d windows
```

Validate changes with `dart format lib`, `flutter analyze`, and `flutter test`.
